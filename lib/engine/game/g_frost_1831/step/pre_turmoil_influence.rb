# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class PreTurmoilInfluence < Engine::Step::Base
          ACTIONS = %w[choose pass].freeze

          def actions(entity)
            return [] unless entity == @game.turmoil_player

            ACTIONS
          end

          def active?
            !@game.turmoil_player.nil?
          end

          def blocking?
            active?
          end

          def active_entities
            [@game.turmoil_player]
          end

          def description
            'Pre-Turmoil: Use Influence'
          end

          def choice_name
            'Use Influence before Turmoil?'
          end

          def choice_view
            :influence_arena
          end

          def choices
            @game.use_influence_choices(@game.turmoil_player)
          end

          def process_choose(action)
            @game.use_turmoil_influence!(action.entity, action.choice)
          end

          def process_pass(action)
            @game.pass_turmoil_influence!(action.entity)
          end
        end
      end
    end
  end
end
