# frozen_string_literal: true

require_relative '../../../round/choices'

module Engine
  module Game
    module GFrost1831
      module Round
        class Voting < Engine::Round::Choices
          def self.short_name
            'VR'
          end

          def name
            'Voting Round'
          end

          def select_entities
            @game.faction_voting_order
          end
        end
      end
    end
  end
end
