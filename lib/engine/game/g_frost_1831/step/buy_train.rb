# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module GFrost1831
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          EXHAUST = 'exhaust'

          def actions(entity)
            actions = super
            return actions if entity != current_entity
            return forced_purchase_actions(entity, actions) if must_buy_train?(entity)

            actions |= %w[choose pass] unless @game.supporter_bypass_choices(entity).empty?
            actions
          end

          def forced_purchase_actions(entity, actions)
            actions = (actions - %w[pass]) | %w[buy_train]
            actions << 'choose' if @game.exhausted?(entity)
            actions
          end

          def buyable_trains(entity)
            trains = super
            return trains unless @game.depot_only_train_purchase?(entity)

            trains.select(&:from_depot?)
          end

          def choice_name
            return 'Supporter Bypass: move 1 Influence onto a train' unless @game.exhausted?(current_entity)

            "#{current_entity.name} cannot buy a train and no Faction can grant a Favor"
          end

          def choices
            return @game.supporter_bypass_choices(current_entity) unless @game.exhausted?(current_entity)

            { EXHAUST => 'Faction Exhaustion (Intervention)' }
          end

          def render_choices?
            @game.exhausted?(current_entity)
          end

          def extra_train_exchanges(corporation)
            @game.supporter_bypass_options(corporation).map do |train, faction_sym|
              {
                from: train.name,
                to: "#{train.name}#{@game.class::SUPPORTER_BYPASS_MARK}",
                choice: @game.supporter_bypass_choice(train, faction_sym),
                label: @game.supporter_bypass_label(faction_sym),
              }
            end
          end

          def process_choose(action)
            return @game.move_influence_to_train!(action.entity, action.choice) unless action.choice == EXHAUST

            @game.exhaust!(action.entity)
            pass!
          end

          def pass_if_cannot_buy_train?(entity)
            @game.supporter_bypass_choices(entity).empty?
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
