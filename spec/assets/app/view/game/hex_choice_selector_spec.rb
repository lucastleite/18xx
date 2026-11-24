# frozen_string_literal: true

require './spec/spec_helper'
require 'lib/hex_choice_selector'
require 'view/game/hex_choice_selector'

module View
  module Game
    describe HexChoiceSelector do
      let(:game) { Engine::Game::GFrost1831::Game.new(%w[a b c], id: 1) }
      let(:gua) { game.corporation_by_id('GUA') }
      let(:exp) { game.corporation_by_id('EXP') }
      let(:selector) { Lib::HexChoiceSelector.new(game.hex_by_id('G14'), [0, 0], 'G14:GUA' => gua, 'G14:EXP' => exp) }
      let(:component) { described_class.new(nil, game: game, tile_selector: selector) }
      let(:logos) { [] }

      before do
        allow(component).to receive(:h) do |tag, props = {}, children = nil|
          logos << props if tag == :img
          [tag, props, children]
        end
        allow(component).to receive(:setting_for).and_return(false)
        allow(component).to receive(:store)
        allow(component).to receive(:process_action)
      end

      it 'shows the logo of each choice around the hex and submits the clicked one' do
        component.render

        expect(logos.map { |props| props[:attrs] }).to eq([{ src: gua.logo, title: 'Guardians' },
                                                           { src: exp.logo, title: 'Expansionists' }])

        logos.last[:on][:click].call

        expect(component).to have_received(:store).with(:tile_selector, nil, skip: true)
        expect(component).to have_received(:process_action) do |action|
          expect(action.choice).to eq('G14:EXP')
        end
      end
    end
  end
end
