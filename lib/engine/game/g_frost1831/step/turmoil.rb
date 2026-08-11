# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Turmoil < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] unless @game.pending_turmoil
            return [] unless entity == pending_corporation

            ACTIONS
          end

          def active_entities
            corp = pending_corporation
            corp ? [corp] : []
          end

          def active?
            !!@game.pending_turmoil
          end

          def blocking?
            active?
          end

          def description
            'Turmoil - Station Loss'
          end

          def help
            data = @game.pending_turmoil
            return '' unless data

            corp = data[:corporation]
            faction = data[:gov_faction]
            [
              "#{corp.full_name} lost Turmoil!",
              "Click on the map to select which station #{faction.full_name} will replace.",
            ]
          end

          def choice_name
            data = @game.pending_turmoil
            return 'Choose a station to lose' unless data

            "#{data[:corporation].name} must choose a station to lose"
          end

          # Return hex names as choices so clicking a hex dispatches the choose action.
          # hex.rb checks: if step.choices.include?(@hex.id) → dispatches Choose action.
          # Setting render_choices? to false suppresses the generic Choose button UI.
          def choices
            data = @game.pending_turmoil
            return {} unless data

            result = {}
            data[:eligible_stations].each do |token|
              hex = token.hex
              next unless hex

              result[hex.name] = hex.name
            end
            result
          end

          def render_choices?
            false
          end

          # Make hexes with corp tokens clickable on the map
          def available_hex(_entity, hex)
            data = @game.pending_turmoil
            return false unless data

            data[:eligible_stations].any? { |t| t.hex == hex }
          end

          def process_choose(action)
            data = @game.pending_turmoil
            return unless data

            hex_name = action.choice.split(':').first
            token = data[:eligible_stations].find { |t| t.hex&.name == hex_name }
            return unless token

            @game.place_turmoil_base(data[:corporation], token, data[:gov_faction])
            @game.clear_pending_turmoil!
          end

          private

          def pending_corporation
            @game.pending_turmoil&.dig(:corporation)
          end
        end
      end
    end
  end
end
