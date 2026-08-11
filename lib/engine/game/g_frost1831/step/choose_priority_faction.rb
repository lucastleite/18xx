# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class ChoosePriorityFaction < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] unless @game.pending_priority_faction_choice
            return [] unless entity == @game.priority_faction_chooser

            ACTIONS
          end

          def active_entities
            return [] unless @game.pending_priority_faction_choice

            [@game.priority_faction_chooser].compact
          end

          def active?
            @game.pending_priority_faction_choice
          end

          def blocking?
            active?
          end

          def description
            'Choose Priority Faction'
          end

          def help
            'The government is neutral. As priority deal holder, choose which faction has priority ' \
              'for the upcoming Voting Round and Operating Rounds.'
          end

          def choice_name
            'Choose Priority Faction'
          end

          def choices
            @game.floated_factions.to_h do |faction|
              [faction.id, @game.faction_display_name(faction.id)]
            end
          end

          def use_faction_icons?
            true
          end

          def show_arena?
            true
          end

          def show_market_regulation?
            true
          end

          def process_choose(action)
            faction_sym = action.choice
            @game.set_priority_faction!(faction_sym)
          end

          def choice_available?(entity)
            entity == @game.priority_faction_chooser && @game.pending_priority_faction_choice
          end

          def ipo_type(_entity)
            nil
          end
        end
      end
    end
  end
end
