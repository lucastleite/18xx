# frozen_string_literal: true

require_relative '../../../round/stock'

module Engine
  module Game
    module GFrost1831
      module Round
        class Stock < Engine::Round::Stock
          def setup
            super
            @finish_round_processed = false
          end

          def finished?
            # Don't finish the round while there's pending influence choice
            return false if @game.pending_influence_choice

            super
          end

          def finish_round
            # Only process finish_round once to avoid infinite loop
            return if @finish_round_processed

            @finish_round_processed = true
            super
          end

          # Override to use operating order instead of alphabetical
          def corporations_to_move_price
            corps = @game.corporations.select { |c| c.floated? && c.type != :minor && c.type != :faction }
            corps.sort
          end
        end
      end
    end
  end
end
