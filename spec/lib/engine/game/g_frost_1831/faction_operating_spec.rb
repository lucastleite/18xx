# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:p1) { game.players[0] }
        let(:p2) { game.players[1] }
        let(:cm) { game.corporation_by_id('CM') }
        let(:tec) { game.corporation_by_id('TEC') }
        let(:home) { 'I6' }

        def tile(name, rotation)
          game.tiles.find { |t| t.name == name }.tap { |t| t.rotate!(rotation) }
        end

        def start_operating_round
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.setup
        end

        def influence(count)
          game.instance_variable_get(:@faction_influence)['TEC'] = count
        end

        def lay(hex_id, name, rotation)
          game.process_action(Engine::Action::LayTile.new(tec, tile: tile(name, rotation), hex: game.hex_by_id(hex_id),
                                                               rotation: rotation))
        end

        def step
          game.round.active_step
        end

        def messages
          game.log.map(&:message)
        end

        before do
          game.phase.next!
          game.event_parliament_opens!
          game.par_corporation(cm, game.stock_market.par_prices.first)
          cm.ipoed = true
          cm.presidents_share.transfer(p1)
          cm.owner = p1
          cm.floated = true
          [tec.presidents_share, tec.ipo_shares.reject(&:president).first].each { |share| share.transfer(p2) }
          tec.owner = p2
          game.hex_by_id(home).tile.cities.first.place_token(tec, tec.next_base, check_tokenable: false)
        end

        it 'gives the Faction its turn before the Corporations, with only the Faction actions' do
          influence(1)
          start_operating_round

          expect(game.round.current_operator).to eq(tec)
          expect(step).to be_a(GFrost1831::Step::FactionAction)
          expect(game.round.actions_for(tec)).to contain_exactly('lay_tile', 'pass')
        end

        it 'lays a yellow tile connected to a base for 1 Influence' do
          influence(3)
          start_operating_round
          lay('H7', '9', 1)

          expect(game.exception&.message).to be_nil
          expect(game.hex_by_id('H7').tile.name).to eq('9')
          expect(game.faction_influence('TEC')).to eq(2)
          expect(messages).to include('TEC lays tile #9 with rotation 1 on H7 for 1 Influence')
          expect(game.round.current_operator).to eq(cm)
        end

        it 'charges more Influence for mountains and upgrades' do
          expect(game.faction_track_cost(game.hex_by_id('J5'), tile('7', 0))).to eq(2)
          expect(game.faction_track_cost(game.hex_by_id('D9'), tile('7', 0))).to eq(3)
          expect(game.faction_track_cost(game.hex_by_id('H7'), tile('26', 0))).to eq(2)
          expect(game.faction_track_cost(game.hex_by_id('H7'), tile('39', 0))).to eq(3)
        end

        it 'offers only the tiles the Faction can pay for' do
          influence(1)
          start_operating_round

          expect(step.potential_tiles(tec, game.hex_by_id('H7'))).not_to be_empty
          expect(step.potential_tiles(tec, game.hex_by_id('J5'))).to be_empty
        end

        it 'places a base connected by track for 5 Influence and moves right in Parliament' do
          game.hex_by_id('H7').lay(tile('9', 1))
          game.hex_by_id('G8').lay(tile('57', 1))
          game.clear_graph
          influence(5)
          price = tec.share_price.price
          start_operating_round

          expect(step.actions(tec)).to include('place_token')

          city = game.hex_by_id('G8').tile.cities.first
          game.process_action(Engine::Action::PlaceToken.new(tec, city: city, slot: 0))

          expect(game.exception&.message).to be_nil
          expect(city.tokens.first.corporation).to eq(tec)
          expect(game.faction_influence('TEC')).to eq(0)
          expect(tec.share_price.price).to be > price
          expect(messages).to include('TEC places a token on G8 for 5 Influences',
                                      "TEC's value increases to #{game.format_currency(tec.share_price.price)}")
        end

        it 'never acts in New London or Grand Junction' do
          influence(5)
          start_operating_round

          expect(step.available_hex(tec, game.hex_by_id('D7'))).to be_nil
          expect(step.available_hex(tec, game.hex_by_id('M6'))).to be_nil
        end

        context 'with a base in New London' do
          let(:home) { 'D7' }

          it 'gains 1 Influence in Parliament for a New London Route section' do
            influence(3)
            government = game.government_marker
            start_operating_round
            lay('D9', '7', 2)

            expect(game.exception&.message).to be_nil
            expect(game.faction_influence('TEC')).to eq(1)
            expect(messages).to include('TEC gains 1 Influence from New London Route (D9)')
            expect(game.government_marker).not_to eq(government)
          end
        end

        it 'pays dividends to the certificate holders after the action' do
          influence(2)
          game.instance_variable_get(:@intervention_certificates)['TEC'] = 1
          p2_cash = p2.cash
          price = tec.share_price
          start_operating_round
          game.process_action(Engine::Action::Pass.new(tec))

          expect(game.exception&.message).to be_nil
          expect(messages).to include('TEC earns £70 (£20 phase base income, £20 bases, '\
                                      '£10 Intervention Certificates, £20 Influence)')
          expect(messages).to include('TEC pays £14 per certificate (£28 to P2)')
          expect(p2.cash).to eq(p2_cash + 28)
          expect(tec.share_price).to eq(price)
          expect(game.round.current_operator).to eq(cm)
          expect(tec.operating_history.values.last.revenue).to eq(70)
        end

        it 'counts the revenue of the base cities for the current phase' do
          influence(0)
          game.hex_by_id('D15').tile.cities.first.place_token(tec, tec.next_base, check_tokenable: false, cheater: true)
          start_operating_round

          expect(messages).to include('TEC earns £80 (£20 phase base income, £60 bases)')
        end

        it 'shows the Influence cost of each Faction action' do
          influence(1)
          start_operating_round

          expect(step.entity_view(step.current_entity)).to eq(:faction_costs)
          expect(game.faction_action_costs).to eq([
            ['Lay yellow tile (plain)', 1],
            ['Lay yellow tile (mountain £50)', 2],
            ['Lay yellow tile (mountain £80)', 3],
            ['Upgrade to green', 2],
            ['Upgrade to brown', 3],
            ['Upgrade to gray', 4],
            ['Place a base', 5],
          ])
        end

        it 'only pays dividends without Influence' do
          influence(0)
          start_operating_round

          expect(messages).to include('TEC earns £40 (£20 phase base income, £20 bases)')
          expect(game.round.current_operator).to eq(cm)
        end
      end
    end
  end
end
