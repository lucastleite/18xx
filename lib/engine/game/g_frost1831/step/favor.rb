# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module GFrost1831
      module Step
        class Favor < Engine::Step::SpecialChoose
          def actions(entity)
            return [] if !@game.favor?(entity) || !entity.owner || !@game.can_request_favor?(entity.owner)

            ACTIONS
          end

          def description
            'Favor'
          end

          def choices_ability(entity)
            @game.favor_choices(entity.owner)
          end

          def ability_views(entity)
            [['GFrost1831::Favor', { corporation: entity.owner }]]
          end

          def process_choose_ability(action)
            @game.grant_favor!(action.entity.owner, action.choice)
          end
        end
      end
    end
  end
end
