# frozen_string_literal: true

require_relative '../../graph'

module Engine
  module Game
    module GFrost1831
      # The home hex counts as a station only until the corporation places its
      # first one (so it can lay track before the home token goes down). After
      # that only real stations connect: a station lost in Turmoil or Intervention
      # no longer connects anything, even on the home hex.
      class Graph < Engine::Graph
        def home_hexes(corporation)
          return {} if corporation.tokens.any?(&:used)

          super
        end

        def home_hex_nodes(corporation)
          return {} if corporation.tokens.any?(&:used)

          super
        end
      end
    end
  end
end
