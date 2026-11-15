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
        let(:lor) { game.corporation_by_id('LOR') }
        let(:favor) { game.companies.find { |c| c.sym == 'FAV' } }

        def float(corporation, cash)
          game.par_corporation(corporation, game.stock_market.par_prices.first)
          corporation.ipoed = true
          corporation.floated = true
          corporation.presidents_share.transfer(p1)
          corporation.owner = p1
          game.bank.spend(cash, corporation) if cash.positive?
        end

        def start_operating_round
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.setup
        end

        def request_favor(choice)
          game.process_action(Engine::Action::ChooseAbility.new(favor, choice: choice))
          expect(game.exception&.message).to be_nil
        end

        def move_to(corporation, coordinates)
          price = game.stock_market.share_price(coordinates)
          corporation.share_price.corporations.delete(corporation)
          corporation.share_price = price
          price.corporations << corporation
        end

        def go_to_buy_train
          50.times do
            break if step.is_a?(GFrost1831::Step::BuyTrain) && game.round.current_operator == cm

            game.process_action(Engine::Action::Pass.new(game.current_entity))
            expect(game.exception&.message).to be_nil
          end
        end

        def must_buy_without_route!
          allow(game).to(receive(:must_buy_train?).and_wrap_original { |_original, entity| entity.trains.empty? })
        end

        def step
          game.round.active_step
        end

        def messages
          game.log.map(&:message)
        end

        context 'once Parliament is open' do
          before do
            game.phase.next!
            game.event_parliament_opens!
            float(cm, 400)
            game.apply_faction_influence!(cm, 'TEC')
            game.buy_train(cm, game.depot.min_depot_train, :free)
          end

          it 'offers a Favor from every Faction with £100 and a token during the operating turn' do
            start_operating_round

            expect(favor.owner).to eq(cm)
            expect(game.round.actions_for(favor)).to eq(%w[choose_ability])
            expect(game.favor_choices(cm)).to include(
              'LOR:TEC' => 'Spend Technicians Influence (←2)',
              'LOR:none' => 'Without spending Influence (←4)',
            )
            expect(game.favor_choices(cm).keys.map { |c| c.split(':').first }.uniq).to eq(%w[TEC LOR GUA EXP])
          end

          it 'pays £100, takes a token and moves the Influence to the Faction' do
            start_operating_round
            request_favor('LOR:TEC')

            expect(cm.cash).to eq(500)
            expect(lor.cash).to eq(400)
            expect(lor.tokens_available).to eq(7)
            expect(game.corporation_influence_for(cm, 'TEC')).to eq(0)
            expect(game.faction_influence('LOR')).to eq(1)
            expect(cm.share_price.coordinates).to eq([1, 2])
            expect(game.favors_used(cm)).to eq(1)
            expect(game.status_array(cm)).to include(['Favors: 1/5', ''])
            expect(messages).to include('CM receives Favor (£100) from LOR', 'CM sends Influence from TEC to LOR')
          end

          it 'discards the Influence sent to a Faction at its limit' do
            game.instance_variable_get(:@faction_influence)['LOR'] = game.faction_influence_limit
            start_operating_round
            request_favor('LOR:TEC')

            expect(game.corporation_influence_for(cm, 'TEC')).to eq(0)
            expect(game.faction_influence('LOR')).to eq(game.faction_influence_limit)
            expect(messages).to include('CM sends Influence (LOR at limit, Influence returned)')
          end

          it 'moves the share price further without spending Influence, following R4' do
            game.regulations['R4'][:position] = GFrost1831::Game::LOOSE
            start_operating_round
            request_favor('LOR:none')

            expect(cm.share_price.coordinates).to eq([1, 1])
            expect(game.corporation_influence_for(cm, 'TEC')).to eq(1)
            expect(game.faction_influence('LOR')).to eq(0)
          end

          it 'allows 1 Favor per Operating Round' do
            start_operating_round
            request_favor('LOR:none')

            expect(game.round.actions_for(favor)).to be_empty
            expect(game.favor_choices(cm)).to be_empty

            start_operating_round
            expect(game.round.actions_for(favor)).to eq(%w[choose_ability])
          end

          it 'allows 5 Favors per game' do
            game.instance_variable_get(:@favors_used)[cm.id] = 5
            start_operating_round

            expect(game.round.actions_for(favor)).to be_empty
          end

          it 'skips Factions without £100 or tokens' do
            tec.spend(450, game.bank)
            move_to(lor, [9, 8])
            start_operating_round

            expect(game.available_favor_factions.map(&:id)).to eq(%w[GUA EXP])
          end

          it 'starts an Intervention when the Favor reaches the Intervention Zone' do
            move_to(cm, [6, 2])
            start_operating_round
            request_favor('LOR:TEC')

            expect(messages).to include('-- CM enters Intervention Zone! --')
          end

          it 'is not offered to the next Corporation after the operating turn' do
            float(dl, 400)
            game.buy_train(dl, game.depot.min_depot_train, :free)
            start_operating_round
            game.round.next_entity!

            expect(game.round.current_operator).to eq(dl)
            expect(favor.owner).to eq(dl)
          end
        end

        context 'in a forced train purchase' do
          before do
            game.phase.next!
            game.event_parliament_opens!
            float(cm, 0)
            float(dl, 400)
            game.buy_train(dl, game.depot.min_depot_train, :free)
            move_to(cm, [1, 11])
            must_buy_without_route!
          end

          it 'exceeds the Favor limits until the Corporation can buy the cheapest train' do
            game.instance_variable_get(:@favors_used)[cm.id] = 5
            start_operating_round
            go_to_buy_train
            request_favor('LOR:none')

            expect(game.favors_used(cm)).to eq(6)
            expect(step.actions(cm)).to eq(%w[buy_train])
            expect(game.round.actions_for(favor)).to be_empty
          end

          it 'buys only from the Depot after a second Favor' do
            game.depot.depot_trains.select { |t| t.name == '2' }.each { |t| t.instance_variable_set(:@price, 180) }
            start_operating_round
            go_to_buy_train
            request_favor('LOR:none')

            expect(game.forced_favor?(cm)).to be(true)
            expect(step.buyable_trains(cm)).to include(dl.trains.first)

            request_favor('GUA:none')

            expect(cm.cash).to eq(200)
            expect(step.buyable_trains(cm)).not_to include(dl.trains.first)
          end

          it 'lets the Corporation undergo Faction Exhaustion when no Faction can grant a Favor' do
            game.factions.each { |faction| faction.spend(faction.cash, game.bank) }
            start_operating_round
            go_to_buy_train

            expect(step.actions(cm)).to contain_exactly('buy_train', 'choose')
            expect(step.choices).to eq('exhaust' => 'Faction Exhaustion (Intervention)')

            game.process_action(Engine::Action::Choose.new(cm, choice: 'exhaust'))

            expect(game.exception&.message).to be_nil
            expect(messages).to include('-- CM enters Intervention Zone! --', 'CM is removed from the game')
            expect(messages).not_to include(a_string_matching(/Faction Exhaustion/))
            expect(cm).to be_closed
          end

          it 'rejects Faction Exhaustion while a Faction can grant a Favor' do
            start_operating_round
            go_to_buy_train

            expect(step.actions(cm)).to eq(%w[buy_train])

            game.process_action(Engine::Action::Choose.new(cm, choice: 'exhaust'))
            expect(game.exception&.message).to start_with('Blocking step Buy Trains cannot process action choose')
          end
        end

        context 'before Parliament opens' do
          before do
            float(cm, 0)
            float(dl, 400)
            game.buy_train(dl, game.depot.min_depot_train, :free)
            move_to(cm, [1, 11])
            must_buy_without_route!
          end

          it 'offers a Favor in Phase 2 and keeps the Faction price when Parliament opens' do
            start_operating_round
            go_to_buy_train

            expect(game.round.actions_for(favor)).to eq(%w[choose_ability])

            request_favor('LOR:none')
            game.event_parliament_opens!

            expect(cm.cash).to eq(100)
            expect(lor.cash).to eq(400)
            expect(lor.tokens_available).to eq(7)
            expect(lor.share_price.price).to eq(80)
          end
        end
      end
    end
  end
end
