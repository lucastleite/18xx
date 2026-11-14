# frozen_string_literal: true

require_relative '../../../step/track'
require_relative '../../../step/tokener'
require_relative 'new_london_route'

module Engine
  module Game
    module GFrost1831
      module Step
        class FactionAction < Engine::Step::Track
          include Engine::Step::Tokener
          include NewLondonRoute

          def actions(entity)
            return [] if entity != current_entity || entity.type != :faction

            actions = []
            actions << 'lay_tile' if can_lay_tile?(entity)
            actions << 'place_token' if can_place_token?(entity)
            actions << 'pass' unless actions.empty?
            actions
          end

          def description
            'Lay Track or Place a Base'
          end

          def pass_description
            'Skip (Track/Base)'
          end

          def entity_views(_entity)
            [['GFrost1831::FactionCosts', { game: @game }]]
          end

          def can_lay_tile?(entity)
            @game.faction_influence(entity.id) >= @game.faction_track_cost_minimum && super
          end

          def can_place_token?(entity)
            @game.faction_influence(entity.id) >= @game.faction_base_cost &&
              entity.tokens_available.positive? && super
          end

          def available_hex(entity, hex)
            return nil if @game.faction_excluded_hex?(hex)

            (can_lay_tile?(entity) && tracker_available_hex(entity, hex)) ||
              (can_place_token?(entity) && tokener_available_hex(entity, hex))
          end

          def potential_tiles(entity, hex)
            influence = @game.faction_influence(entity.id)
            super.select { |tile| @game.faction_track_cost(hex, tile) <= influence }
          end

          def process_lay_tile(action)
            entity = action.entity
            hex = action.hex
            raise GameError, "#{entity.full_name} cannot lay track in #{hex.name}" if @game.faction_excluded_hex?(hex)

            cost = @game.faction_track_cost(hex, action.tile)
            raise GameError, "#{entity.full_name} needs #{cost} Influence" if cost > @game.faction_influence(entity.id)

            lay_tile_action(action)
            pass!
          end

          def pay_tile_cost!(entity, tile, rotation, hex, _spender, _cost, _extra_cost)
            cost = @game.faction_track_cost(hex, tile)
            @game.spend_faction_influence!(entity, cost)
            @log << "#{entity.name} lays tile ##{tile.name} with rotation #{rotation} on #{hex.name} "\
                    "for #{cost} Influence"
          end

          def process_place_token(action)
            entity = action.entity
            hex = action.city.hex
            raise GameError, "#{entity.full_name} cannot place a base in #{hex.name}" if @game.faction_excluded_hex?(hex)

            raise GameError, 'Token is already used' if action.token.used

            check_connected(entity, action.city, hex)
            action.city.place_token(entity, action.token, free: true)
            @game.clear_graph_for_entity(entity)
            @game.place_faction_base!(entity, hex)
            pass!
          end
        end
      end
    end
  end
end
