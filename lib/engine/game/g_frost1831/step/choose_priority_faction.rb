# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class ChoosePriorityFaction < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] unless pending_choice?
            return [] unless entity == chooser

            ACTIONS
          end

          def active_entities
            return [] unless pending_choice?

            [chooser].compact
          end

          def active?
            pending_choice?
          end

          def blocking?
            active?
          end

          def description
            if @game.pending_or_priority_choice
              'Choose Operating Order'
            else
              'Choose Voting Order'
            end
          end

          def help
            if @game.pending_or_priority_choice
              'The government is neutral. As priority deal holder, choose which faction operates first this Operating Round.'
            else
              'The government is neutral. As priority deal holder, choose which faction goes first in the upcoming Voting Round.'
            end
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
            if @game.pending_or_priority_choice
              @game.set_or_priority_faction!(faction_sym)
            else
              @game.set_priority_faction!(faction_sym)
            end
          end

          def choice_available?(entity)
            entity == chooser && pending_choice?
          end

          def ipo_type(_entity)
            nil
          end

          private

          def pending_choice?
            @game.pending_priority_faction_choice || @game.pending_or_priority_choice
          end

          def chooser
            @game.pending_or_priority_choice ? @game.or_priority_chooser : @game.priority_faction_chooser
          end
        end
      end
    end
  end
end
