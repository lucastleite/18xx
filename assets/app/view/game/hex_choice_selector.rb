# frozen_string_literal: true

require 'lib/radial_selector'
require 'lib/settings'
require 'view/game/actionable'

module View
  module Game
    class HexChoiceSelector < Snabberb::Component
      include Actionable
      include Lib::RadialSelector
      include Lib::Settings

      needs :tile_selector, store: true
      needs :zoom, default: 1

      LOGO_SIZE = 40

      def render
        size = LOGO_SIZE * @zoom
        logos = list_coordinates(@tile_selector.choices.to_a, size, size / 2).map do |(choice, entity), left, bottom|
          h(:img, {
              attrs: { src: setting_for(:simple_logos, @game) ? entity.simple_logo : entity.logo, title: entity.full_name },
              on: { click: -> { choose(choice) } },
              style: style(left, bottom, size),
            })
        end

        h(:div, logos)
      end

      private

      def choose(choice)
        store(:tile_selector, nil, skip: true)
        process_action(Engine::Action::Choose.new(@game.current_entity, choice: choice))
      end
    end
  end
end
