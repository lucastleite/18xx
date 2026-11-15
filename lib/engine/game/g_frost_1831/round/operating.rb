# frozen_string_literal: true

require_relative '../../../round/operating'

module Engine
  module Game
    module GFrost1831
      module Round
        class Operating < Engine::Round::Operating
          def after_setup
            super unless @game.first_operating_faction_pending?
          end

          def start_operating
            entity = @entities[@entity_index]
            unless skip_entity?(entity)
              pass_steps_of_other_operators!(entity)
              @game.assign_favor!(entity)
            end
            super
          end

          def first_operating_faction_chosen!
            @entities = select_entities
            after_setup
          end

          private

          def pass_steps_of_other_operators!(operator)
            faction_turn = operator.type == :faction
            @steps.each { |step| step.pass! if faction_step?(step) != faction_turn }
          end

          def faction_step?(step)
            step.is_a?(GFrost1831::Step::FactionAction) || step.is_a?(GFrost1831::Step::FactionDividend)
          end
        end
      end
    end
  end
end
