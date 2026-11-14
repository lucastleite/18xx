# frozen_string_literal: true

require_relative '../../../round/operating'

module Engine
  module Game
    module GFrost1831
      module Round
        class Operating < Engine::Round::Operating
          def after_setup
            super unless @game.first_operating_faction_pending?
          end

          def skip_entity?(entity)
            entity.type == :faction || super
          end

          def first_operating_faction_chosen!
            @entities = select_entities
            after_setup
          end
        end
      end
    end
  end
end
