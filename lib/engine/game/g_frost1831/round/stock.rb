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

            # Don't finish while pending priority faction choice
            return false if @game.pending_priority_faction_choice

            super
          end

          def finish_round
            # Only process finish_round once to avoid infinite loop
            return if @finish_round_processed

            @finish_round_processed = true

            # Check if we need priority faction choice BEFORE calling super
            # Calculate the priority player manually using last_to_act
            if should_trigger_priority_faction_choice?
              # Calculate who has priority: player after last_to_act
              players = @game.players.reject(&:bankrupt)
              last_to_act = @last_to_act
              priority_idx = last_to_act ? (players.index(last_to_act) + 1) % players.size : 0
              priority_player = players[priority_idx]
              @game.trigger_priority_faction_choice!(priority_player)
            end

            super
          end

          private

          def should_trigger_priority_faction_choice?
            return false unless @game.government_neutral?
            return false unless @game.parliament_open?

            @game.corporations.count { |c| c.type == :faction && c.floated? } >= 2
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
