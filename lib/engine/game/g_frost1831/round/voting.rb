# frozen_string_literal: true

require_relative '../../../round/choices'

module Engine
  module Game
    module GFrost1831
      module Round
        class Voting < Engine::Round::Choices
          def self.round_name
            'Voting Round'
          end

          def self.short_name
            'VR'
          end

          def name
            "Voting Round #{@game.turn}"
          end

          def show_in_history?
            false
          end

          def voting?
            true
          end

          def select_entities
            # Factions that participate in voting (with presidents), in Arena order
            @game.faction_voting_order
          end

          def finished?
            @game.voting_finished?
          end
        end
      end
    end
  end
end
