# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class FirstOperatingFaction < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def actions(entity)
            return [] if !active? || entity != chooser

            ACTIONS
          end

          def active?
            @game.first_operating_faction_pending?
          end

          def blocking?
            active?
          end

          def active_entities
            [chooser]
          end

          def description
            'Choose the first Faction'
          end

          def help
            'The Government is Neutral: the Priority Deal holder chooses the first Faction to operate. '\
              'The others follow in Influence Arena order.'
          end

          def choice_available?(entity)
            entity == chooser
          end

          def choice_name
            'Which Faction operates first?'
          end

          def choices
            @game.founded_factions.to_h { |faction| [faction.id, faction.full_name] }
          end

          def process_choose(action)
            faction = @game.founded_factions.find { |f| f.id == action.choice }
            raise GameError, "#{action.choice} is not a founded Faction" unless faction

            @game.choose_first_operating_faction!(action.entity, faction)
            @round.first_operating_faction_chosen!
          end

          private

          def chooser
            @game.first_operating_faction_chooser
          end
        end
      end
    end
  end
end
