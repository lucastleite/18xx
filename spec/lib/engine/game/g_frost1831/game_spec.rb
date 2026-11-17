# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        def new_game(num_players, id: 1)
          Engine::Game::GFrost1831::Game.new((1..num_players).map { |i| "Player #{i}" }, id: id)
        end

        it 'has the expected title and aliases' do
          expect(Meta::GAME_TITLE).to eq('Frost 1831')
          expect(Meta::GAME_ALIASES).to eq(['1831'])
        end

        it 'adds the Influence limits to the phase table' do
          game = new_game(3)

          expect(game.phase_extra_columns).to eq(['◆ Corp Limit', '◆ Faction Limit'])
          expect(game.phase.phases.map { |phase| game.phase_extra_columns.map { |c| game.phase_extra_value(phase, c) } })
            .to eq([[3, 6], [4, 6], [4, 6], [5, 8], [5, 8], [5, 10]])
        end

        it 'adds the Parliament tab' do
          expect(new_game(3).extra_game_tabs.map { |tab| tab[:anchor] }).to eq(['parliament'])
        end

        describe 'spreadsheet' do
          let(:game) do
            Engine::Game.load(JSON.parse(File.read('spec/fixtures/frost1831/hs_fqaxxsno_1794865941.json')), at_action: 300)
          end

          def row(id)
            corporation = game.corporation_by_id(id)
            game.spreadsheet_extra_columns.map { |column| game.spreadsheet_extra_value(corporation, column) }
          end

          def sorted(column)
            game.all_corporations.sort_by { |c| game.spreadsheet_extra_sort_value(c, column) }.reverse.map(&:id)
          end

          it 'adds the Favors column and one Influence column per Faction' do
            expect(game.spreadsheet_extra_columns).to eq(%w[Favors TEC LOR GUA EXP])
            expect(row('SP')).to eq(['1/5', '', '', '4/5', '4/5'])
            expect(row('OE')).to eq(['0/5', '2/5', '3/5', '', ''])
            expect(row('GUA')).to eq(['4/5', '', '', '5/8', ''])
          end

          it 'sorts a Faction column with the Faction first, then its supporters by Influence' do
            expect(sorted('GUA').first(4)).to eq(%w[GUA SP CM EC])
            expect(sorted('Favors').first(2)).to eq(%w[EXP LOR])
          end
        end

        it 'shows the Market row only on the Corporation charters' do
          game = new_game(3)

          expect(game.show_market_row?(game.corporation_by_id('GUA'))).to be(false)
          expect(game.show_market_row?(game.corporation_by_id('SP'))).to be(true)
        end

        it 'lists the Factions before the Corporations on the player card' do
          game = Engine::Game.load(JSON.parse(File.read('spec/fixtures/frost1831/hs_fqaxxsno_1794865941.json')), at_action: 300)
          player = game.players.find { |p| p.name == 'Player 2' }
          shares = player.shares_by_corporation.reject { |_, s| s.empty? }

          expect(game.player_shares_sort(player, shares).map { |c, _| c.name }).to eq(%w[LOR GUA HF])
        end

        it 'plays with 2 to 5 players' do
          expect(Meta::PLAYER_RANGE).to eq([2, 5])
        end

        {
          2 => { cert_limit: 31, cash: 1200 },
          3 => { cert_limit: 25, cash: 800 },
          4 => { cert_limit: 22, cash: 600 },
          5 => { cert_limit: 19, cash: 480 },
        }.each do |num_players, expected|
          it "initializes with #{num_players} players without error" do
            game = new_game(num_players)
            expect(game.cert_limit).to eq(expected[:cert_limit])
            expect(game.players.map(&:cash).uniq).to eq([expected[:cash]])
          end
        end

        it 'loads the eight corporations' do
          game = new_game(3)
          corporations = game.corporations.reject { |c| c.type == :faction }
          expect(corporations.map(&:id).sort).to eq(%w[CM DL EC GJ HF OE SP TV])
        end

        describe 'first-to-arrive market cells' do
          let(:game) { new_game(3) }
          let(:market) { game.stock_market }
          let(:first_to_arrive_messages) { game.log.map(&:message).grep(/is first to reach/) }

          def place(corporation, coordinates)
            price = market.share_price(coordinates)
            corporation.share_price = price
            price.corporations << corporation
          end

          def move_right(corporation)
            from = corporation.share_price
            market.move_right(corporation)
            game.share_price_changed(corporation, from)
          end

          it 'marks seven cells' do
            expect(market.share_prices_with_types([:pays_bonus_1]).map(&:price)).to eq([300, 240, 200, 160, 120, 80, 60])
          end

          it 'turns the cell into a normal one when the first corporation arrives' do
            corporation = game.corporation_by_id('CM')
            place(corporation, [1, 11])

            move_right(corporation)

            expect(corporation.share_price.price).to eq(300)
            expect(corporation.share_price.types).to be_empty
            expect(market.share_prices_with_types([:pays_bonus_1]).size).to eq(6)
            expect(first_to_arrive_messages.size).to eq(1)
            expect(first_to_arrive_messages.first).to include('CM')
          end

          it 'does not claim the cell again for the next corporation' do
            first = game.corporation_by_id('CM')
            second = game.corporation_by_id('DL')
            place(first, [1, 11])
            place(second, [1, 11])

            move_right(first)
            move_right(second)

            expect(second.share_price).to eq(first.share_price)
            expect(first_to_arrive_messages.size).to eq(1)
          end
        end

        describe 'home station on an OO hex' do
          let(:game) { new_game(3) }
          let(:tv) { game.corporation_by_id('TV') }

          before do
            par = game.stock_market.par_prices.find { |price| price.price == 100 }
            tv.ipoed = true
            tv.par_price = par
            tv.share_price = par
            5.times { game.share_pool.transfer_shares(tv.ipo_shares.first.to_bundle, game.players.first) }
            game.bank.spend(500, tv)
            game.place_home_token(tv)
            game.instance_variable_set(:@round, game.operating_round(1))
            game.round.goto_entity!(tv)
          end

          it 'asks for the home city again after an OO tile is laid over the station' do
            tile = game.tiles.find { |t| t.name == 'O1' }
            game.process_action(Engine::Action::LayTile.new(tv, tile: tile, hex: game.hex_by_id('I12'), rotation: 0))

            expect(game.exception).to be_nil
            expect(game.round.active_step).to be_a(Step::HomeToken)

            city = game.hex_by_id('I12').tile.cities.first
            game.process_action(Engine::Action::PlaceToken.new(tv, city: city, slot: 0))

            expect(city.tokened_by?(tv)).to be(true)
          end
        end

        describe 'station hexes' do
          let(:game) { new_game(3) }
          let(:gj) { game.corporation_by_id('GJ') }

          before do
            par = game.stock_market.par_prices.find { |price| price.price == 100 }
            gj.ipoed = true
            gj.par_price = par
            gj.share_price = par
            5.times { game.share_pool.transfer_shares(gj.ipo_shares.first.to_bundle, game.players.first) }
            game.bank.spend(500, gj)
            game.place_home_token(gj)
            game.instance_variable_set(:@round, game.operating_round(1))
            game.round.goto_entity!(gj)
          end

          it 'does not highlight a reachable hex where the Corporation already has a station' do
            home = game.hex_by_id('M6')
            step = game.round.steps.find { |s| s.is_a?(Step::Token) }

            expect(game.token_graph_for_entity(gj).reachable_hexes(gj)).to include(home)
            expect(step.available_hex(gj, home)).to be_falsey
          end
        end

        it 'ends only when the Bank breaks' do
          expect(Game::GAME_END_CHECK).to eq(bank: :full_or)
        end

        it 'shows the thematic train names in the Info tab' do
          game = new_game(3)
          names = %w[2 3 4 5 6 D].map { |name| game.info_train_name(game.depot.upcoming.find { |t| t.name == name }) }

          expect(names).to eq(['2 (Hope)', '3 (Long John)', '4 (Ice Breaker)', '5 (The Queen)', '6 (Nightmare)',
                               'D (Silver Bullet)'])
        end

        describe 'Tight Regulation' do
          it 'starts every Market Regulation at Normal by default' do
            game = new_game(3)

            expect(Game::REGULATIONS.keys.map { |r| game.regulation_value(r) }.uniq).to eq([Game::NORMAL])
          end

          it 'starts every Market Regulation at Tight with the optional rule' do
            game = Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1, optional_rules: [:tight_regulation])

            expect(Game::REGULATIONS.keys.map { |r| game.regulation_value(r) }.uniq).to eq([Game::TIGHT])
            expect(game.corporation_by_id('CM').max_ownership_percent).to eq(50)
            expect(game.favor_market_penalty(true)).to eq(3)
            expect(game.favor_market_penalty(false)).to eq(4)
          end
        end
      end
    end
  end
end
