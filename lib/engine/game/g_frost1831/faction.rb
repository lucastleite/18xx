# frozen_string_literal: true

require_relative '../../corporation'
require_relative '../../token'

module Engine
  module Game
    module GFrost1831
      # A Faction starts with 9 tokens in Parliament (1 base + 8). Each Favor or
      # additional base takes one out and moves the Faction 1 space right on its
      # Parliament track, so the track position counts the tokens spent.
      #
      # Only bases on the map are real tokens: the Faction starts with its home
      # base and gets a new token each time it places another base.
      class Faction < Engine::Corporation
        TOKENS = 9

        attr_accessor :bases_lost

        def initialize(**opts)
          super
          @bases_lost = 0
        end

        # Favors and additional bases taken from Parliament
        def tokens_spent
          share_price&.coordinates&.[](1) || 0
        end

        # Tokens still able to become a Favor or an additional base
        def tokens_available
          [TOKENS - 1 - tokens_spent, 0].max
        end

        # Tokens still in Parliament, including the home base before it is placed
        def tokens_in_parliament
          home_placed = @tokens.any?(&:used) || @bases_lost.positive?
          tokens_available + (home_placed ? 0 : 1)
        end

        # Bases lost in the Blizzard leave the game
        def tokens_total
          TOKENS - @bases_lost
        end

        def find_token_by_type(type = nil)
          super || next_base
        end

        def tokens_by_type
          unplaced = super
          unplaced.empty? ? [next_base] : unplaced
        end

        def next_base
          @next_base = nil if @next_base&.used
          @next_base ||= BaseToken.new(self, price: 0)
        end

        class BaseToken < Engine::Token
          def place(location, extra: nil, cheater: nil)
            corporation.tokens << self unless corporation.tokens.include?(self)
            super
          end
        end
      end
    end
  end
end
