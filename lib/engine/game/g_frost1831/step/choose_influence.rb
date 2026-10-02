# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class ChooseInfluence < Engine::Step::Base
          # When a corporation gains an influence cube (NL route, market bonus),
          # the president must choose which supported faction receives it.

          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] unless @game.pending_influence_choice
            
            # The entity making the choice is the corporation (or its president decides)
            choice_entity = @game.pending_influence_choice[:corporation]
            return [] unless entity == choice_entity

            ACTIONS
          end

          def active?
            !!@game.pending_influence_choice
          end

          def blocking?
            !!@game.pending_influence_choice
          end

          def active_entities
            return [] unless @game.pending_influence_choice

            [@game.pending_influence_choice[:corporation]]
          end

          def current_entity
            return nil unless @game.pending_influence_choice

            @game.pending_influence_choice[:corporation]
          end

          def choice_available?(entity)
            return false unless @game.pending_influence_choice

            entity == @game.pending_influence_choice[:corporation]
          end

          def ipo_type(_entity)
            nil
          end

          def description
            'Choose Faction for Influence'
          end

          def choices
            factions = @game.pending_influence_choice[:factions]
            factions.map { |f| [f, faction_name(f)] }.to_h
          end

          def choice_name
            corp = @game.pending_influence_choice[:corporation]
            reason = @game.pending_influence_choice[:reason]
            if reason
              "Allocate Influence for #{corp.name} (#{reason}) to which faction?"
            else
              "Allocate Influence for #{corp.name} to which faction?"
            end
          end

          def render_choices?
            false
          end

          def process_choose(action)
            faction_sym = action.choice
            corp = @game.pending_influence_choice[:corporation]
            @log << "#{corp.name} allocates influence to #{faction_name(faction_sym)}"
            @game.resolve_influence_choice(faction_sym)
          end

          private

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
