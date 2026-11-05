# frozen_string_literal: true

require 'view/game/player'

module View
  module Game
    module GFrost1831
      # Custom player card for Frost 1831 - shows factions before corporations
      class Player < View::Game::Player
        def render_shares
          shares = @player
            .shares_by_corporation.reject { |_, s| s.empty? }

          # Partition into factions and corps, sort each group
          factions, corps = shares.partition { |c, _| c.type == :faction }

          sorted_factions = factions.sort_by { |c, s| [-s.sum(&:percent), c.president?(@player) ? 0 : 1, c.name] }
          sorted_corps = corps.sort_by { |c, s| [-s.sum(&:percent), c.president?(@player) ? 0 : 1, c.name] }

          # Factions first, then corporations
          ordered = sorted_factions + sorted_corps

          h(:table, ordered.map { |c, s| render_corporation_shares(c, s) })
        end
      end
    end
  end
end
