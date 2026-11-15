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
        let(:dl) { game.corporation_by_id('DL') }
        let(:sp) { game.corporation_by_id('SP') }
        let(:tec) { game.corporation_by_id('TEC') }
        let(:level1) { [2, 3] }
        let(:level2) { [1, 2] }
        let(:level3) { [0, 1] }

        def float(corporation, president, factions, coordinates)
          game.par_corporation(corporation, game.stock_market.par_prices.first)
          corporation.ipoed = true
          corporation.floated = true
          corporation.presidents_share.transfer(president)
          corporation.owner = president
          game.instance_variable_get(:@corporation_factions)[corporation.id] = factions
          move_to(corporation, coordinates)
        end

        def move_to(corporation, coordinates)
          price = game.stock_market.share_price(coordinates)
          corporation.share_price.corporations.delete(corporation)
          corporation.share_price = price
          price.corporations << corporation
        end

        def cubes(corporation, faction_sym, count)
          game.instance_variable_get(:@corporation_influence)[corporation.id] = { faction_sym => count }
        end

        def station(corporation, hex_id, city_index = 0)
          game.hex_by_id(hex_id).tile.cities[city_index]
              .place_token(corporation, corporation.next_token, check_tokenable: false)
        end

        def turmoil(position)
          game.instance_variable_set(:@government_marker, position)
          game.event_turmoil!
        end

        def start_operating_round
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.setup
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
          float(cm, p1, %w[TEC LOR], [1, 4])
          float(dl, p2, %w[TEC EXP], [1, 5])
          float(sp, p2, %w[GUA EXP], [1, 4])
          cubes(cm, 'TEC', 1)
          cubes(sp, 'GUA', 1)
        end

        it 'picks the Corporation with the most Influence of the Faction as its Main Supporter' do
          expect(game.main_supporter('TEC')).to eq(cm)

          cubes(cm, 'TEC', 0)
          expect(game.main_supporter('TEC')).to eq(dl)
        end

        it 'moves the Main Supporters of the Government right and of the Opposition left at level 1' do
          turmoil(level1)

          expect(cm.share_price.coordinates).to eq([1, 5])
          expect(sp.share_price.coordinates).to eq([1, 3])
          expect(game.faction_influence('TEC')).to eq(0)
          expect(messages).to include('CM (Government supporter) gains market value',
                                      'SP (Opposition supporter) loses market value')
        end

        it 'logs the Influence that cannot be gained or lost at level 2' do
          game.instance_variable_get(:@faction_influence)['TEC'] = game.faction_influence_limit
          cubes(sp, 'GUA', 0)
          turmoil(level2)

          expect(messages).to include('Technicians at Parliament limit — Influence not gained',
                                      'Guardians has no Influence in Parliament — no loss',
                                      'SP has no Influence for Guardians — no loss')
        end

        it 'moves Influence of the Factions and their Main Supporters at level 2' do
          game.instance_variable_get(:@faction_influence)['GUA'] = 1
          turmoil(level2)

          expect(game.faction_influence('TEC')).to eq(1)
          expect(game.corporation_influence_for(cm, 'TEC')).to eq(2)
          expect(game.faction_influence('GUA')).to eq(0)
          expect(game.corporation_influence_for(sp, 'GUA')).to eq(0)
          expect(game.government_marker).to eq(level2)
          expect(messages).to include('CM gains 1 Influence (Technicians)', 'SP loses 1 Influence (Guardians)')
        end

        it 'does not move the Government Marker when the Main Supporter reaches the Influence Zone' do
          move_to(cm, [1, 12])
          turmoil(level1)
          game.resolve_influence_choice!('TEC')

          expect(game.corporation_influence_for(cm, 'TEC')).to eq(2)
          expect(game.government_marker).to eq(level1)
        end

        context 'at level 3' do
          before { start_operating_round }

          it 'gives the Main Supporter of the Government a Favor without moving its share price' do
            turmoil(level3)

            expect(cm.cash).to eq(100)
            expect(tec.cash).to eq(400)
            expect(tec.tokens_available).to eq(7)
            expect(cm.share_price.coordinates).to eq([1, 5])
            expect(game.favors_used(cm)).to eq(1)
            expect(messages).to include('CM receives Favor (£100) from TEC (no market penalty)')
          end

          it 'grants no Favor without £100 in the Treasury' do
            tec.spend(tec.cash, game.bank)
            turmoil(level3)

            expect(cm.cash).to eq(0)
            expect(messages).to include('Technicians cannot grant a Favor to CM (insufficient Treasury)')
          end

          it 'lets the President choose the station of the Opposition Main Supporter replaced by a Government base' do
            station(sp, 'D15')
            station(sp, 'J9')
            turmoil(level3)

            expect(step).to be_a(GFrost1831::Step::TurmoilStationLoss)
            expect(step.help).to eq(["Snow Pilgrims' Railway lost Turmoil!",
                                     'Click on the map to select which station Technicians will replace.'])
            expect(step.can_replace_token?(sp, sp.tokens.first)).to be(true)

            city = game.hex_by_id('J9').tile.cities.first
            game.process_action(Engine::Action::RemoveToken.new(sp, city: city, slot: 0))

            expect(game.exception&.message).to be_nil
            expect(city.tokens.first.corporation).to eq(tec)
            expect(sp.tokens.count(&:used)).to eq(1)
            expect(messages).to include("TEC replaces SP's station on J9 (Turmoil)")
            expect(game.turmoil_station_loss).to be_nil
          end

          it 'does not give the Government a second base in the same hex' do
            station(sp, 'D15')
            station(sp, 'I12', 1)
            station(tec, 'I12', 0)
            turmoil(level3)

            expect(game.turmoil_station_loss).to be_nil
            expect(game.hex_by_id('D15').tile.cities.first.tokens.compact.map(&:corporation)).to eq([tec])
            expect(game.hex_by_id('I12').tile.cities[1].tokens.compact.map(&:corporation)).to eq([sp])
          end

          it 'keeps the stations when the Government has no tokens' do
            move_to(tec, [9, 8])
            station(sp, 'D15')
            station(sp, 'J9')
            turmoil(level3)

            expect(game.turmoil_station_loss).to be_nil
            expect(sp.tokens.count(&:used)).to eq(2)
            expect(messages).to include('Technicians has no available markers — no station loss')
          end

          it 'keeps the only station of the Opposition Main Supporter' do
            station(sp, 'D15')
            turmoil(level3)

            expect(game.turmoil_station_loss).to be_nil
            expect(sp.tokens.count(&:used)).to eq(1)
            expect(messages).to include('SP has only 1 station(s) — no loss')
          end

          it 'starts the Intervention only after every consequence' do
            move_to(sp, [6, 1])
            station(sp, 'D15')
            station(sp, 'J9')
            turmoil(level3)

            expect(sp.share_price.coordinates).to eq([6, 0])
            expect(game.close_corporations_in_close_cell!).to be_nil

            city = game.hex_by_id('J9').tile.cities.first
            game.process_action(Engine::Action::RemoveToken.new(sp, city: city, slot: 0))

            expect(messages).to include('-- SP enters Intervention Zone! --')
          end
        end

        context 'with players holding Influence' do
          before do
            start_operating_round
            game.instance_variable_get(:@player_influence)[p2.id] = 1
          end

          it 'lets them allocate it before the consequences' do
            cubes(dl, 'TEC', 1)
            turmoil(level1)

            expect(step).to be_a(GFrost1831::Step::PreTurmoilInfluence)
            expect(game.current_entity).to eq(p2)
            expect(messages).not_to include(a_string_starting_with('Government: '))

            game.process_action(Engine::Action::Choose.new(p2, choice: 'DL:TEC'))

            expect(game.exception&.message).to be_nil
            expect(dl.share_price.coordinates).to eq([1, 6])
            expect(cm.share_price.coordinates).to eq([1, 4])
          end

          it 'applies the consequences when they pass' do
            turmoil(level1)
            game.process_action(Engine::Action::Pass.new(p2))

            expect(game.exception&.message).to be_nil
            expect(messages).to include('P2 passes on using Influence', 'Government: Technicians (Level 1)')
            expect(cm.share_price.coordinates).to eq([1, 5])
          end
        end
      end
    end
  end
end
