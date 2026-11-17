# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:p1) { game.players[0] }
        let(:p2) { game.players[1] }
        let(:tec) { game.corporation_by_id('TEC') }
        let(:lor) { game.corporation_by_id('LOR') }
        let(:gua) { game.corporation_by_id('GUA') }
        let(:lords_government) { [1, 6] }
        let(:neutral) { [3, 4] }

        def found(faction, president, influence: 0)
          faction.floated = true
          faction.presidents_share.transfer(president)
          faction.owner = president
          game.instance_variable_get(:@faction_influence)[faction.id] = influence
        end

        def start_voting_round(government = lords_government)
          game.instance_variable_set(:@government_marker, government)
          game.instance_variable_set(:@round, game.new_voting_round)
          game.round.setup
        end

        def choose(choice)
          game.process_action(Engine::Action::Choose.new(game.round.active_step.current_entity, choice: choice),
                              add_auto_actions: true)
          expect(game.exception&.message).to be_nil
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
          found(lor, p2, influence: 2)
          found(tec, p1, influence: 1)
        end

        describe 'after the Stock Round' do
          before { game.instance_variable_set(:@round, game.send(:new_stock_round)) }

          it 'holds a Voting Round once Parliament is open' do
            game.send(:next_round!)

            expect(game.round).to be_a(GFrost1831::Round::Voting)
            expect(messages).to include('-- Voting Round 1 --')
          end

          it 'skips the Voting Round without founded Factions' do
            [tec, lor].each { |faction| faction.floated = false }
            game.send(:next_round!)

            expect(game.round).to be_a(Engine::Round::Operating)
          end
        end

        it 'starts with the Government, which must move its criterion 1 space for free' do
          start_voting_round

          expect(step).to be_a(GFrost1831::Step::Proposal)
          expect(step.current_entity).to eq(lor)
          expect(step.choices.keys).to eq(%w[R1 R2 R3 R4 pass])

          choose('R1')

          expect(step).to be_a(GFrost1831::Step::Vote)
          expect(step.current_entity).to eq(lor)
          expect(step.choices).to eq('Loose' => 'Loosen (0◆)', 'Tight' => 'Tighten (0◆)')

          choose('Loose')

          expect(game.regulation_setting('R1')).to eq('Loose')
          expect(game.faction_influence('LOR')).to eq(2)
          expect(messages).to include('P2 (LOR) chooses R1. Track Laying', 'P2 (LOR) votes R1. Track Laying: Normal -> Loose')
        end

        it 'lets every Faction, the proposer included, spend 1 Influence per move until all pass' do
          start_voting_round
          choose('R1')
          choose('Tight')

          expect(step.current_entity).to eq(tec)
          expect(step.choices).to eq('Normal' => 'Normalize (1◆)', 'pass' => 'Maintain (0◆)')

          choose('Normal')
          expect(step.current_entity).to eq(lor)
          choose('Tight')

          expect(game.faction_influence('TEC')).to eq(0)
          expect(game.faction_influence('LOR')).to eq(1)
          expect(messages.last).to eq('P1 (TEC) auto-maintains (no influence)')
          expect(step.current_entity).to eq(lor)

          choose('pass')

          expect(game.regulation_setting('R1')).to eq('Tight')
          expect(game.locked_regulation?('R1')).to be(true)
          expect(messages).to include('P1 (TEC) votes R1. Track Laying: Tight -> Normal (spends 1 Influence)',
                                      'P2 (LOR) maintains',
                                      'R1 (Track Laying) is locked at Tight')
          expect(step).to be_a(GFrost1831::Step::Proposal)
          expect(step.current_entity).to eq(tec)
          expect(step.choices.keys).to eq(%w[R2 R3 R4 pass])
        end

        it 'passes automatically for a Faction without Influence' do
          game.instance_variable_get(:@faction_influence)['TEC'] = 0
          start_voting_round
          choose('R2')
          choose('Loose')

          expect(messages.last).to eq('P1 (TEC) auto-maintains (no influence)')
          expect(step.current_entity).to eq(lor)
          expect(step.choices.keys).to eq(%w[Normal pass])
        end

        it 'waits for a President who can still give Influence to the Faction' do
          game.instance_variable_get(:@faction_influence)['TEC'] = 0
          game.instance_variable_get(:@player_influence)[p1.id] = 1

          start_voting_round
          choose('R2')
          choose('Loose')

          expect(step.current_entity).to eq(tec)
          expect(step.choices).to eq('pass' => 'Maintain (0◆)')
        end

        it 'ends a Proposal that passes without changing or locking a criterion' do
          start_voting_round
          choose('pass')

          expect(messages).to include('P2 (LOR) passes on proposing')
          expect(step.current_entity).to eq(tec)
          expect(step.choices.keys).to eq(%w[R1 R2 R3 R4 pass])
        end

        it 'ends after one Proposal per founded Faction and starts the Operating Round' do
          start_voting_round
          choose('pass')
          choose('pass')

          expect(game.round).to be_a(Engine::Round::Operating)
        end

        it 'applies the Corporation Limit immediately' do
          cm = game.corporation_by_id('CM')
          start_voting_round
          choose('R3')
          choose('Tight')

          expect(cm.max_ownership_percent).to eq(50)
        end

        it 'rejects a move of more than 1 space' do
          start_voting_round
          choose('R4')
          game.process_action(Engine::Action::Choose.new(lor, choice: 'pass'))

          expect(game.exception&.message).to eq('R4 (Favor) cannot move to pass')
        end

        context 'with a Neutral Government' do
          it 'lets the Priority Deal holder choose the first Faction' do
            found(gua, game.players[2])
            start_voting_round(neutral)

            expect(step).to be_a(GFrost1831::Step::FirstVotingFaction)
            expect(step.choice_name).to eq('Which Faction votes first?')
            expect(step.logo_choices?).to be(true)

            game.process_action(Engine::Action::Choose.new(p1, choice: 'GUA'))

            expect(game.exception&.message).to be_nil
            expect(messages).to include('P1 chooses Guardians as priority faction for Voting Round')
            expect(game.faction_voting_order).to eq([gua, tec, lor])
            expect(step.current_entity).to eq(gua)
          end
        end
      end
    end
  end
end
