# frozen_string_literal: true

require_relative '../../../step/token'

module Engine
  module Game
    module GFrost1831
      module Step
        class Token < Engine::Step::Token
          def available_hex(entity, hex)
            super && hex.tile.cities.any? do |city|
              !@game.reserved_for_faction?(city) && city.tokenable?(entity, free: true)
            end
          end

          def place_token(entity, city, token, **kwargs)
            raise GameError, "#{city.hex.name} is reserved for a Faction base" if @game.reserved_for_faction?(city)

            super
          end
        end
      end
    end
  end
end
