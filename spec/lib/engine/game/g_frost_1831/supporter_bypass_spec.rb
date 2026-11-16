# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:p1) { game.players[0] }
        let(:dl) { game.corporation_by_id('DL') }
        let(:tec) { game.corporation_by_id('TEC') }
        let(:gua) { game.corporation_by_id('GUA') }
        let(:train) { game.depot.trains.find { |t| t.name == '3' } }

        def lay(hex_id, name, rotation)
          tile = game.tiles.find { |t| t.name == name && !t.hex }
          tile.rotate!(rotation)
          game.hex_by_id(hex_id).lay(tile)
        end

        def city(hex_id)
          game.hex_by_id(hex_id).tile.cities.first
        end

        def route
          data = { 'train' => train.id, 'connections' => [%w[M8 M10], %w[M10 M12]] }
          action_data = { 'type' => 'run_routes', 'entity' => 'DL', 'entity_type' => 'corporation', 'routes' => [data] }
          Engine::Action::RunRoutes.from_h(action_data, game).routes.first
        end

        before do
          game.par_corporation(dl, game.stock_market.par_prices.first)
          dl.ipoed = true
          dl.floated = true
          dl.presidents_share.transfer(p1)
          dl.owner = p1
          game.instance_variable_get(:@corporation_factions)[dl.id] = %w[TEC LOR]
          game.add_corporation_influence!(dl, 'TEC')
          %w[M8 M10 M12].each { |hex_id| lay(hex_id, '57', 0) }
          city('M10').remove_all_reservations!
          city('M8').place_token(dl, dl.next_token, check_tokenable: false)
          game.buy_train(dl, train, :free)
        end

        it 'offers to move 1 Influence from the charter onto each kind of train without one' do
          expect(game.supporter_bypass_choices(dl)).to eq("diamond_#{train.id}_TEC" => '3 → 3◆: Influence by Technicians')

          game.move_influence_to_train!(dl, "diamond_#{train.id}_TEC")

          expect(game.corporation_influence_for(dl, 'TEC')).to eq(0)
          expect(game.supporter_bypass?(train)).to be(true)
          expect(game.supporter_bypass_choices(dl)).to eq({})
          expect(game.trains_str(dl)).to eq(['3◆'])
          expect(game.log.last.message).to eq('DL moves 1 Technicians Influence onto a 3-train (Supporter Bypass)')
        end

        it 'lets the President move the Influence during the train-buying step' do
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.goto_entity!(dl)
          step = game.round.steps.find { |s| s.is_a?(GFrost1831::Step::BuyTrain) }

          expect(step.actions(dl)).to include('choose', 'pass')
          expect(step.choice_name).to eq('Supporter Bypass: move 1 Influence onto a train')
          expect(step.choices).to eq(game.supporter_bypass_choices(dl))
          exchange = { from: '3', to: '3◆', choice: "diamond_#{train.id}_TEC", label: 'Influence by Technicians' }
          expect(step.extra_train_exchanges(dl)).to eq([exchange])
          expect(step.render_choices?).to be(false)

          step.process_choose(Engine::Action::Choose.new(dl, choice: "diamond_#{train.id}_TEC"))

          expect(game.supporter_bypass?(train)).to be(true)
          expect(step.actions(dl)).not_to include('choose')
        end

        it 'keeps the train-buying step open for the Supporter Bypass after reaching the train limit' do
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.goto_entity!(dl)
          step = game.round.steps.find { |s| s.is_a?(GFrost1831::Step::BuyTrain) }
          twos = game.depot.trains.select { |t| t.name == '2' }
          twos.first(2).each { |t| game.buy_train(dl, t, :free) }
          game.bank.spend(80, dl)

          step.process_buy_train(Engine::Action::BuyTrain.new(dl, train: twos[2], price: 80))

          expect(dl.trains.size).to eq(game.train_limit(dl))
          expect(step.passed?).to be_falsey
          expect(step.actions(dl)).to include('choose', 'pass')
        end

        it 'passes through a city blocked by a supported Faction only with Influence on the train' do
          city('M10').place_token(tec, tec.next_base, check_tokenable: false)

          expect { route.revenue }.to raise_error(GameError, 'Route is not connected')

          game.move_influence_to_train!(dl, "diamond_#{train.id}_TEC")

          expect(route.visited_stops.map(&:hex).map(&:id)).to eq(%w[M8 M10 M12])
          expect(route.revenue).to eq(route.visited_stops.sum { |stop| stop.route_revenue(game.phase, train) })
        end

        it 'does not pass through a city blocked by a Faction the Corporation does not support' do
          city('M10').place_token(gua, gua.next_base, check_tokenable: false)
          game.move_influence_to_train!(dl, "diamond_#{train.id}_TEC")

          expect { route.revenue }.to raise_error(GameError, 'Route is not connected')
        end

        it 'only ignores blocked cities in the graph while running routes' do
          game.move_influence_to_train!(dl, "diamond_#{train.id}_TEC")
          route_step = Engine::Step::Route.new(game, game.round)

          allow(game.round).to receive(:active_step).and_return(route_step)
          expect(game.graph_for_entity(dl).no_blocking?).to be(true)

          allow(game.round).to receive(:active_step).and_return(nil)
          expect(game.graph_for_entity(dl)).to eq(game.graph)
        end

        it 'keeps the Influence on a train bought from another Corporation' do
          game.move_influence_to_train!(dl, "diamond_#{train.id}_TEC")
          cm = game.corporation_by_id('CM')
          game.bank.spend(1, cm)
          game.buy_train(cm, train, 1)

          expect(game.supporter_bypass?(train)).to be(true)
          expect(game.trains_str(cm)).to eq(['3◆'])
        end
      end
    end
  end
end
