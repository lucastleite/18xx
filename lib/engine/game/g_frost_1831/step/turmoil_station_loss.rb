# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class TurmoilStationLoss < Engine::Step::Base
          def actions(entity)
            return [] unless entity == corporation

            %w[remove_token]
          end

          def active?
            !@game.turmoil_station_loss.nil?
          end

          def blocking?
            active?
          end

          def active_entities
            [corporation]
          end

          def description
            "Turmoil: #{corporation.name} loses a station"
          end

          def help
            ["#{corporation.full_name} lost Turmoil!",
             "Click on the map to select which station #{faction.full_name} will replace."]
          end

          def ipo_type(_entity)
            nil
          end

          def available_hex(_entity, hex)
            @game.turmoil_stations.any? { |token| token.city.hex == hex }
          end

          def can_replace_token?(entity, token)
            entity == corporation && @game.turmoil_stations.include?(token)
          end

          def process_remove_token(action)
            token = action.city.tokens[action.slot]
            raise GameError, 'This station cannot be replaced' unless can_replace_token?(action.entity, token)

            @game.replace_turmoil_station!(token)
          end

          private

          def corporation
            @game.turmoil_station_loss[:corporation]
          end

          def faction
            @game.turmoil_station_loss[:faction]
          end
        end
      end
    end
  end
end
