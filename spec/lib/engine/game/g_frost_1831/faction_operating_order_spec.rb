# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:cm) { game.corporation_by_id('CM') }
        let(:tec) { game.corporation_by_id('TEC') }
        let(:lor) { game.corporation_by_id('LOR') }
        let(:gua) { game.corporation_by_id('GUA') }
        let(:exp) { game.corporation_by_id('EXP') }

        def found(*factions)
          factions.each { |faction| faction.floated = true }
        end

        def start_operating_round(government)
          game.instance_variable_set(:@government_marker, government)
          game.instance_variable_set(:@round, game.new_operating_round(1))
          game.round.setup
        end

        def choose(faction)
          game.process_action(Engine::Action::Choose.new(game.players.first, choice: faction.id))
          expect(game.exception&.message).to be_nil
        end

        def step
          game.round.active_step
        end

        before do
          game.par_corporation(cm, game.stock_market.par_prices.first)
          cm.ipoed = true
          cm.presidents_share.transfer(game.players.first)
          cm.owner = game.players.first
          cm.floated = true
        end

        it 'puts the founded Factions before the Corporations, starting with the Government' do
          found(tec, gua, exp)
          start_operating_round([1, 6])

          expect(game.round.entities).to eq([gua, exp, tec, cm])
          expect(game.round.current_operator).to eq(cm)
        end

        it 'lets the Priority Deal holder choose the first Faction when the Government is Neutral' do
          found(tec, gua, exp)
          start_operating_round([3, 4])

          expect(step).to be_a(GFrost1831::Step::FirstOperatingFaction)
          expect(game.active_players).to eq([game.players.first])
          expect(step.choices).to eq('TEC' => 'Technicians', 'GUA' => 'Guardians', 'EXP' => 'Expansionists')
          expect(game.round.current_operator).to be_nil

          choose(exp)

          expect(game.round.entities).to eq([exp, tec, gua, cm])
          expect(game.round.current_operator).to eq(cm)
          expect(game.log.map(&:message)).to include('P1 chooses Expansionists as first faction for Operating Round')
        end

        it 'asks again in each Operating Round with a Neutral Government' do
          found(tec, gua)
          start_operating_round([3, 4])
          choose(gua)
          game.instance_variable_set(:@round, game.new_operating_round(2))
          game.round.setup

          expect(step).to be_a(GFrost1831::Step::FirstOperatingFaction)
        end

        it 'does not ask with a single founded Faction' do
          found(lor)
          start_operating_round([3, 4])

          expect(game.round.entities).to eq([lor, cm])
          expect(game.round.current_operator).to eq(cm)
        end

        it 'lists the Factions in Arena order from the Government, then the floated, parred and other Corporations' do
          dl = game.corporation_by_id('DL')
          game.par_corporation(dl, game.stock_market.par_prices.first)
          dl.ipoed = true
          game.instance_variable_set(:@government_marker, [1, 6])

          sorted = game.sorted_corporations
          expect(sorted.first(6)).to eq([lor, gua, exp, tec, cm, dl])
          expect(sorted.drop(6)).to eq(game.corporations.reject { |c| c.type == :faction || [cm, dl].include?(c) })
        end

        it 'lists the Factions before the Corporations among the entities without an owner' do
          expect(game.bank_sort([cm, tec, game.corporation_by_id('DL'), exp]).map(&:id)).to eq(%w[EXP TEC CM DL])
        end

        it 'rejects a Faction that is not founded' do
          found(tec, gua)
          start_operating_round([3, 4])
          game.process_action(Engine::Action::Choose.new(game.players.first, choice: 'LOR'))

          expect(game.exception&.message).to eq('LOR is not a founded Faction')
        end
      end
    end
  end
end
