# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:p1) { game.players[0] }
        let(:cm) { game.corporation_by_id('CM') }
        let(:dl) { game.corporation_by_id('DL') }
        let(:tec) { game.corporation_by_id('TEC') }

        def float(corporation, par)
          game.par_corporation(corporation, game.stock_market.par_prices.find { |p| p.price == par })
          corporation.ipoed = true
          corporation.floated = true
          corporation.presidents_share.transfer(p1)
          corporation.owner = p1
          game.bank.spend(1000, corporation)
        end

        def station(corporation, hex_id)
          token = corporation.type == :faction ? corporation.next_base : corporation.next_token
          game.hex_by_id(hex_id).tile.cities.first.place_token(corporation, token, check_tokenable: false)
        end

        def lay_yellow(hex_id, name, rotation = 0)
          tile = game.tiles.find { |t| t.name == name }
          tile.rotate!(rotation)
          game.tiles.delete(tile)
          game.hex_by_id(hex_id).lay(tile)
          tile
        end

        def blizzard
          game.event_blizzard!
          game.action_processed(nil)
        end

        def icons(hex_id)
          game.hex_by_id(hex_id).tile.icons.map(&:name)
        end

        def messages
          game.log.map(&:message)
        end

        it 'clears every Blizzard symbol' do
          blizzard

          expect(game.blizzard_hexes).to be_empty
          expect(messages).to include('-- Event: Blizzard! --')
        end

        it 'returns the yellow tiles in Blizzard hexes to the supply and charges the mountain again' do
          yellow = lay_yellow('C6', '9', 1)
          blizzard

          expect(game.hex_by_id('C6').tile).to eq(game.hex_by_id('C6').original_tile)
          expect(game.hex_by_id('C6').tile.upgrades.map(&:cost)).to eq([50])
          expect(game.tiles).to include(yellow)
          expect(messages).to include(a_string_matching(/^Tiles removed: .*C6/))
        end

        it 'keeps green tiles and their stations' do
          float(cm, 100)
          station(cm, 'E10')
          station(cm, 'J9')
          allow(game.hex_by_id('E10').tile).to receive(:color).and_return(:green)
          blizzard

          expect(cm.tokens.count(&:used)).to eq(2)
        end

        it 'removes a Corporation without stations, without an Intervention' do
          float(cm, 100)
          station(cm, 'E10')
          blizzard

          expect(cm).to be_closed
          expect(messages).to include('Stations/bases destroyed: CM (E10)',
                                      'CM has no stations left after the Blizzard', 'CM is removed from the game')
          expect(messages).not_to include('-- CM enters Intervention Zone! --')
          expect(p1.companies).to be_empty
        end

        it 'does not ask a Corporation removed by the Blizzard to discard trains' do
          float(cm, 100)
          station(cm, 'E10')
          game.depot.upcoming.select { |t| t.name == '2' }.first(5).each { |t| game.buy_train(cm, t, :free) }
          expect(game.crowded_corps).to include(cm)

          blizzard

          expect(cm).to be_closed
          expect(game.crowded_corps).not_to include(cm)
        end

        it 'keeps a Corporation with a station outside the Blizzard' do
          float(cm, 100)
          station(cm, 'E10')
          station(cm, 'J9')
          blizzard

          expect(cm).not_to be_closed
          expect(cm.tokens.count(&:used)).to eq(1)
        end

        it 'removes Faction bases permanently' do
          game.event_parliament_opens!
          station(tec, 'E10')
          blizzard

          expect(tec.tokens_total).to eq(8)
          expect(messages).to include('Stations/bases destroyed: TEC (E10)')
        end

        it 'does not give the New London Route Influence again after the yellow tile is removed' do
          lay_yellow('C8', '9', 1)
          game.hex_by_id('C8').tile.icons.reject! { |icon| icon.name == 'influence_cube' }
          blizzard

          expect(icons('C8')).to be_empty
        end

        it 'keeps the New London Route Influence that was not collected' do
          lay_yellow('C8', '9', 1)
          blizzard

          expect(icons('C8')).to eq(%w[influence_cube])
        end

        it 'removes the cheapest train from the Train Depot from the second Corporation removed' do
          float(cm, 100)
          float(dl, 100)
          station(cm, 'E10')
          station(dl, 'F9')
          train = game.depot.min_depot_train
          blizzard

          expect([cm, dl]).to all(be_closed)
          expect(game.depot.upcoming).not_to include(train)
        end

        it 'removes the operating Corporation after its 5-train purchase' do
          float(cm, 100)
          float(dl, 70)
          station(cm, 'E10')
          station(dl, 'J9')
          game.depot.upcoming.reject! { |t| %w[2 3 4].include?(t.name) }
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.setup
          20.times do
            break if game.round.active_step.is_a?(GFrost1831::Step::BuyTrain)

            game.process_action(Engine::Action::Pass.new(game.current_entity))
          end
          train = game.depot.min_depot_train

          game.process_action(Engine::Action::BuyTrain.new(cm, train: train, price: train.price))

          expect(game.exception&.message).to be_nil
          expect(cm).to be_closed
          expect(game.round.current_operator).to eq(dl)
        end

        describe 'market and phase reference' do
          it 'shows the Favor penalty of the current Favor Regulation in the price movement chart' do
            expect(game.price_movement_chart).to include(['Faction Favor, sending Influence', '2 ←'],
                                                         ['Faction Favor, without Influence', '4 ←'])

            game.move_regulation('R4', :up)

            expect(game.price_movement_chart).to include(['Faction Favor, sending Influence', '3 ←'],
                                                         ['Faction Favor, without Influence', '4 ←'])
          end

          it 'shows the phase events as phase statuses' do
            statuses = game.class::PHASES.to_h { |phase| [phase[:name], phase[:status] || []] }

            expect(statuses['3']).to include('parliament_opens')
            expect(statuses['4']).to include('turmoil')
            expect(statuses['5']).to eq(['blizzard'])
            expect(statuses['6']).to eq(['turmoil'])
            expect(statuses['D']).to eq(['turmoil'])
          end
        end
      end
    end
  end
end
