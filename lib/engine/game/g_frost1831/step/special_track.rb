# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative '../../../step/track_lay_when_company_sold'

module Engine
  module Game
    module GFrost1831
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          include Engine::Step::TrackLayWhenCompanySold

          def process_lay_tile(action)
            # For Diggers/Explorers: remove the tile_lay ability after use
            # This allows using count-less abilities that auto-remove
            entity = action.entity
            if entity.company? && %w[PDI PEX].include?(entity.sym)
              ability = @game.abilities(entity, :tile_lay, time: 'sold')
              if ability
                lay_tile(action, spender: entity.owner)
                @round.laid_hexes << action.hex
                entity.remove_ability(ability)
                @game.after_lay_tile(action.hex, action.tile, entity)
                @company = nil
                return
              end
            end

            super
            @game.after_lay_tile(action.hex, action.tile, action.entity)
          end
        end
      end
    end
  end
end
