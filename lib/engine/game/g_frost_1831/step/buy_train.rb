# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module GFrost1831
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          EXHAUST = 'exhaust'

          def actions(entity)
            return super if entity != current_entity || !must_buy_train?(entity)

            actions = (super - %w[pass]) | %w[buy_train]
            actions << 'choose' if @game.exhausted?(entity)
            actions
          end

          def buyable_trains(entity)
            trains = super
            return trains unless @game.depot_only_train_purchase?(entity)

            trains.select(&:from_depot?)
          end

          def choice_name
            "#{current_entity.name} cannot buy a train and no Faction can grant a Favor"
          end

          def choices
            { EXHAUST => 'Faction Exhaustion (Intervention)' }
          end

          def process_choose(action)
            @game.exhaust!(action.entity)
            pass!
          end

          def ebuy_president_can_contribute?(_corporation)
            false
          end

          def president_may_contribute?(_entity, _shell = nil)
            false
          end
        end
      end
    end
  end
end
