# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Intervention < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] unless @game.pending_intervention

            # In Stock Round, the president handles the intervention
            # In Operating Round, the corporation handles it
            if @game.round.stock?
              # Any player can see the intervention, but only president can act
              president = @game.pending_intervention.owner
              return [] unless entity == president

              ACTIONS
            else
              return [] unless entity == @game.pending_intervention

              ACTIONS
            end
          end

          def active_entities
            corp = @game.pending_intervention
            return [] unless corp

            # In Stock Round, the president is active; in OR, the corporation
            if @game.round.stock?
              [corp.owner].compact
            else
              [corp]
            end
          end

          # Override to allow intervention to interrupt normal SR flow
          def pass_if_cannot_act!
            # Don't auto-pass during intervention
          end

          def active?
            !!@game.pending_intervention
          end

          def blocking?
            active?
          end

          # Required by stock round view - return nil as intervention doesn't deal with IPO
          def ipo_type(_corporation)
            nil
          end

          def description
            'Intervention - Token Distribution'
          end

          def help
            data = @game.intervention_data
            return '' unless data

            corp = data[:corporation]
            remaining = data[:opposing].reject { |f| data[:assigned].values.include?(f) }
            
            # Count eligible stations
            stations = data[:stations].reject { |t| data[:assigned].key?(t) }
            eligible_stations = stations.select { |t| remaining.any? { |f| @game.faction_can_receive_station?(f, t) } }
            
            faction_names = remaining.map(&:full_name).join(' and ')
            
            instruction = if remaining.size == 1
                            # 1 faction, N stations
                            "Choose a station to give to #{faction_names}."
                          elsif eligible_stations.size == 1
                            # 2 factions, 1 station
                            "Choose which faction between #{faction_names} receives the station."
                          else
                            # 2 factions, 2+ stations
                            "Choose stations to distribute between #{faction_names}."
                          end
            
            [
              "#{corp.full_name} is being intervened.",
              instruction,
            ]
          end

          def choice_name
            'Choose a city to replace'
          end

          def choice_available?(entity)
            active? && actions(entity).include?('choose')
          end

          def choices
            @game.intervention_station_choices
          end

          # Don't render choice buttons - player clicks on map instead
          def render_choices?
            false
          end

          # Make hexes with corp tokens clickable on the map
          def available_hex(_entity, hex)
            data = @game.intervention_data
            return false unless data

            eligible_hexes(data).include?(hex)
          end

          # Returns the faction options for a given hex (used by the front-end selector)
          def faction_options_for_hex(hex)
            data = @game.intervention_data
            return [] unless data

            remaining_factions = data[:opposing].reject { |f| data[:assigned].values.include?(f) }

            token = data[:stations].find { |t| !data[:assigned].key?(t) && t.hex == hex }
            return [] unless token

            remaining_factions.select { |f| @game.faction_can_receive_station?(f, token) }
          end

          def process_choose(action)
            @game.process_intervention_choice(action.choice)
          end

          private

          def eligible_hexes(data)
            stations = data[:stations].reject { |t| data[:assigned].key?(t) }
            remaining_factions = data[:opposing].reject { |f| data[:assigned].values.include?(f) }

            stations.filter_map do |token|
              hex = token.hex
              next unless hex

              # Hex is eligible only if at least one remaining faction can receive a base there
              eligible = remaining_factions.any? { |f| @game.faction_can_receive_station?(f, token) }
              hex if eligible
            end
          end
        end
      end
    end
  end
end
