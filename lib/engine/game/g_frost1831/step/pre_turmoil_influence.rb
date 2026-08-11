# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class PreTurmoilInfluence < Engine::Step::Base
          ACTIONS = %w[choose pass].freeze

          def actions(entity)
            return [] unless @game.pre_turmoil_window
            return [] unless entity == current_player_with_influence

            ACTIONS
          end

          def active_entities
            player = current_player_with_influence
            player ? [player] : []
          end

          def active?
            !!@game.pre_turmoil_window
          end

          def blocking?
            active?
          end

          def description
            'Pre-Turmoil: Use Influence'
          end

          def choice_name
            'Use Influence before Turmoil?'
          end

          def choices
            player = current_player_with_influence
            return {} unless player

            result = {}

            # Get all influence allocation options (same as INF choices)
            @game.corporations.select { |c| c.owner == player && c.type != :faction && @game.corporation_factions(c).any? }.each do |corp|
              @game.corporation_factions(corp).each do |faction|
                next unless @game.within_influence_limit?(corp, faction)

                result["#{corp.id}:#{faction}"] = "#{corp.name} → #{faction_name(faction)}"
              end
            end

            @game.corporations.select { |c| c.owner == player && c.type == :faction }.each do |faction|
              next unless @game.faction_influence(faction.id) < @game.faction_influence_limit

              result["faction:#{faction.id}"] = faction.name
            end

            result
          end

          def process_choose(action)
            player = action.entity
            choice = action.choice

            raise GameError, 'No Influence to allocate' unless @game.player_influence(player).positive?

            @game.player_influence_spend(player)

            if choice.start_with?('faction:')
              faction_sym = choice.split(':').last
              faction = @game.corporations.find { |c| c.id == faction_sym }
              raise GameError, 'Not president of that faction' unless faction&.owner == player

              @game.faction_influence_gain(faction_sym)
              @log << "#{player.name} allocates influence directly to #{faction.name}"
            else
              corp_id, faction_sym = choice.split(':')
              corporation = @game.corporations.find { |c| c.id == corp_id }
              raise GameError, 'Not president of that corporation' unless corporation&.owner == player

              @game.add_corporation_influence(corporation, faction_sym)
              @log << "#{player.name} allocates influence to #{corporation.name} (#{faction_name(faction_sym)})"
            end

            # Close INF company if no more cubes
            inf_company = player.companies.find { |c| c.sym == 'INF' }
            unless @game.player_influence(player).positive?
              inf_company&.close!
              @log << 'Use Influence ability consumed'
              # No more influence, remove from list
              remove_player_from_window(player)
            end
            # If player still has influence, they stay in the window (can use again or pass next)
          end

          def process_pass(action)
            player = action.entity
            @log << "#{player.name} passes on using Influence"
            remove_player_from_window(player)
          end

          private

          def current_player_with_influence
            window = @game.pre_turmoil_window
            return unless window

            window[:players_remaining]&.first
          end

          def remove_player_from_window(player)
            window = @game.pre_turmoil_window
            return unless window

            window[:players_remaining].delete(player)

            # If no more players with influence, execute turmoil
            if window[:players_remaining].empty?
              @game.execute_pending_turmoil!
            end
          end

          def faction_name(sym)
            case sym
            when 'TEC' then 'Technicians'
            when 'GUA' then 'Guardians'
            when 'EXP' then 'Expansionists'
            when 'LOR' then 'Lords'
            else sym
            end
          end
        end
      end
    end
  end
end
