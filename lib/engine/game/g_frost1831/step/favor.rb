# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Favor < Engine::Step::Base
          ACTIONS = %w[choose pass].freeze

          def actions(entity)
            return [] unless entity == current_entity
            return [] if entity.type == :faction
            return [] unless @game.can_request_favor?(entity)

            %w[choose]
          end

          def active?
            !passed? && current_entity && @game.can_request_favor?(current_entity)
          end

          def blocking?
            false
          end

          def description
            'Favor'
          end

          def choice_name
            @selected_faction ? 'Favor Type' : 'Choose Faction'
          end

          def choices
            entity = current_entity
            return {} unless entity

            if @selected_faction
              favor_type_choices(entity)
            else
              faction_choices(entity)
            end
          end

          def process_choose(action)
            entity = action.entity
            choice = action.choice

            if choice.start_with?('faction:')
              # Player selected a faction
              @selected_faction = @game.corporations.find { |c| c.id == choice.split(':').last }
            elsif choice.start_with?('favor:')
              # Player confirmed the favor type
              process_favor(entity, choice)
            end
          end

          def process_pass(_action)
            # Cancel / go back
            if @selected_faction
              @selected_faction = nil
            else
              pass!
            end
          end

          def setup
            @selected_faction = nil
          end

          private

          def faction_choices(entity)
            choices = {}
            @game.available_favor_factions(entity).each do |faction|
              choices["faction:#{faction.id}"] = faction.name
            end
            choices
          end

          def favor_type_choices(entity)
            choices = {}
            corp_factions = @game.corporation_factions(entity)

            corp_factions.each do |faction_sym|
              penalty = @game.favor_market_penalty(entity, @selected_faction, faction_sym)
              choices["favor:#{faction_sym}"] = "Favor with #{@game.faction_display_name(faction_sym)} (←#{penalty})"
            end

            penalty_no_influence = @game.favor_market_penalty(entity, @selected_faction, nil)
            choices['favor:none'] = "Favor without Influence (←#{penalty_no_influence})"

            choices
          end

          def process_favor(entity, choice)
            faction_sym = choice.split(':').last
            with_influence_to = faction_sym == 'none' ? nil : faction_sym

            @game.execute_favor(entity, @selected_faction, with_influence_to)
            @selected_faction = nil
          end
        end
      end
    end
  end
end
