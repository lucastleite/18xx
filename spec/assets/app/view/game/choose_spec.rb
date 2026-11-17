# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/engine/game/g_18_oe/helpers'
require 'view/game/choose'

describe View::Game::Choose do
  include G18OESpecHelpers

  [Engine::Game::G18OE::Game, Engine::Game::G18OEUKFR::Game].each do |klass|
    context "with #{klass.title} Minor C" do
      let(:game) { new_game(%w[a b c], klass: klass) }
      let(:player) { game.players.first }
      let(:minor) { start_minor!(game, 'C', player, 'UK') }
      let(:component) { described_class.new(nil, game: game) }

      it 'renders all positions and submits the choice as C while another railroad is normally first' do
        regional = start_regional!(game, 'PLM', game.players.last)
        minor
        round = enter_round!(game, game.operating_round(1)).tap(&:setup)
        nodes = []
        allow(component).to receive(:h) do |tag, props = {}, children = nil|
          nodes << [tag, props, children]
          [tag, props, children]
        end
        allow(component).to receive(:process_action) { |action| round.process_action(action) }

        component.render
        buttons = nodes.select { |tag, _, _| tag == 'button' }
        expect(buttons.map(&:last)).to eq(%w[First Normal Last])
        expect(round.entities.first).to eq(regional)
        expect(game.current_entity).to eq(minor)

        buttons.first[1][:on][:click].call
        expect(round.current_operator).to eq(minor)
        expect(round.entities).to eq([minor, regional])
        expect(round.actions_for(minor)).to include('lay_tile')
      end
    end
  end

  context 'when the step offers logo choices' do
    let(:game) { Engine::Game::GFrost1831::Game.new(%w[a b c], id: 1) }
    let(:step) do
      double('Step', choices: { 'TEC' => 'Technicians (2)', 'pass' => 'Pass' }, choice_name: 'Pick', logo_choices?: true,
                     current_entity: game.players.first)
    end
    let(:component) { described_class.new(nil, game: game) }
    let(:nodes) { [] }

    before do
      allow(game.round).to receive(:active_step).and_return(step)
      allow(component).to receive(:h) do |tag, props = {}, children = nil|
        nodes << [tag, props, children]
        [tag, props, children]
      end
      allow(component).to receive(:setting_for).and_return(false)
      allow(component).to receive(:process_action)
    end

    it 'shows the logo of each Corporation choice and submits the clicked one' do
      component.render

      logos = nodes.select { |tag, _, _| tag == :img }
      expect(logos.map { |_, props, _| props[:attrs].slice(:src, :title) })
        .to eq([{ src: game.corporation_by_id('TEC').logo, title: 'Technicians (2)' }])
      expect(nodes.select { |tag, _, _| tag == 'button' }.map(&:last)).to eq(['Pass'])

      logos.first[1][:on][:click].call

      expect(component).to have_received(:process_action) do |action|
        expect(action.choice).to eq('TEC')
      end
    end
  end
end
