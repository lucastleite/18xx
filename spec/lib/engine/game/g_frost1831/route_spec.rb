# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:tv) { game.corporation_by_id('TV') }
        let(:train) { game.depot.upcoming.first }

        def stop(hex_id, index = 0)
          tile = game.hex_by_id(hex_id).tile
          (tile.city_towns + tile.offboards)[index]
        end

        def lay(hex_id, name, rotation)
          tile = game.tiles.find { |t| t.name == name && !t.hex }
          tile.rotate!(rotation)
          game.hex_by_id(hex_id).lay(tile)
        end

        describe 'same hex' do
          before do
            lay('I12', 'O1', 0)
            lay('I14', '7', 2)
            lay('H13', '7', 4)
            game.hex_by_id('I12').tile.cities.first.place_token(tv, tv.next_token, check_tokenable: false)
            game.buy_train(tv, train, :free)
          end

          it 'does not let a route stop at both cities of an OO hex' do
            data = { 'train' => train.id, 'connections' => [%w[I12 I14 H13 I12]], 'nodes' => %w[I12-0 I12-1] }
            action_data = { 'type' => 'run_routes', 'entity' => 'TV', 'entity_type' => 'corporation', 'routes' => [data] }
            action = Engine::Action::RunRoutes.from_h(action_data, game)
            route = action.routes.first

            expect(route.visited_stops.map(&:hex).map(&:id)).to eq(%w[I12 I12])
            expect { route.revenue }.to raise_error(GameError, 'Route cannot stop twice in I12')
          end
        end

        describe 'route bonuses' do
          it 'adds £50 to a route through North, New London and South' do
            expect(game.route_bonuses([stop('B1'), stop('D7'), stop('D15')])).to eq([['S-NL-N', 50]])
            expect(game.route_bonuses([stop('A2'), stop('D7', 1), stop('D15')])).to eq([['S-NL-N', 50]])
          end

          it 'adds £70 for each East location on a route through New London' do
            expect(game.route_bonuses([stop('M2'), stop('D7')])).to eq([['NL-E', 70]])
            expect(game.route_bonuses([stop('M2'), stop('D7'), stop('O14')])).to eq([['NL-E', 140]])
          end

          it 'adds both bonuses to the same route' do
            stops = [stop('B1'), stop('D7'), stop('D15'), stop('M2')]

            expect(game.route_bonuses(stops)).to eq([['S-NL-N', 50], ['NL-E', 70]])
          end

          it 'gives no bonus without New London' do
            expect(game.route_bonuses([stop('B1'), stop('I6'), stop('D15'), stop('M2')])).to eq([])
          end

          it 'adds the bonuses to the revenue and the route description' do
            route = instance_double(Engine::Route, phase: game.phase, train: train, hexes: [], visited_stops: [])
            allow(route).to receive(:visited_stops).and_return([stop('M2'), stop('D7')])
            allow(route).to receive(:hexes).and_return([game.hex_by_id('M2'), game.hex_by_id('D7')])

            expect(game.revenue_for(route, route.visited_stops)).to eq(20 + 30 + 70)
            expect(game.revenue_str(route)).to eq('M2-D7 + NL-E(+70)')
          end
        end
      end
    end
  end
end
