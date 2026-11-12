# frozen_string_literal: true

require 'lib/radial_selector'
require 'lib/settings'
require 'view/game/actionable'

module View
  module Game
    module GFrost1831
      class InterventionFactionSelector < Snabberb::Component
        include Actionable
        include Lib::RadialSelector
        include Lib::Settings

        needs :tile_selector, store: true
        needs :zoom, default: 1

        TOKEN_SIZE = 40

        def render
          @token_size = TOKEN_SIZE * @zoom
          @size = @token_size / 2
          @distance = @token_size

          factions = @tile_selector.factions
          hex = @tile_selector.hex

          items = list_coordinates(factions, @distance, @size).map do |faction, left, bottom|
            click = lambda do
              process_action(Engine::Action::Choose.new(
                @game.current_entity,
                choice: "#{hex.name}:#{faction.id}",
              ))
              store(:tile_selector, nil)
            end

            props = {
              attrs: {
                src: setting_for(:simple_logos, @game) ? faction.simple_logo : faction.logo,
              },
              on: {
                click: click,
              },
              style: style(left, bottom, @token_size),
            }

            h(:img, props)
          end

          h(:div, items)
        end
      end
    end
  end
end
