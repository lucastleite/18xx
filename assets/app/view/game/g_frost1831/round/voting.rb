# frozen_string_literal: true

require 'view/game/actionable'
require 'view/game/corporation'
require 'view/game/g_frost1831/market_regulation'

module View
  module Game
    module GFrost1831
      module Round
        # Voting round view for Frost 1831: the choose action, the market
        # regulation table and the faction cards in voting order.
        class Voting < Snabberb::Component
          include Actionable

          needs :game

          def render
            round = @game.round
            @step = round.active_step
            entity = @step.active_entities&.first
            @current_actions = entity ? round.actions_for(entity) : []

            children = []

            children << h(View::Game::Choose) if @current_actions.include?('choose')
            children << h(:div, { style: { width: '100%', maxWidth: '750px' } }, [
              h(MarketRegulation, game: @game),
            ])

            # Show faction cards for decision-making context (in voting order)
            factions = if @game.respond_to?(:faction_voting_order)
                         @game.faction_voting_order
                       else
                         @game.corporations.select { |c| c.type == :faction && c.floated? }
                       end
            if factions.any?
              children << h(:div, {
                              style: {
                                display: 'flex',
                                flexWrap: 'wrap',
                                gap: '0.5rem',
                                marginTop: '1rem',
                              },
                            },
                            factions.map { |f| h(View::Game::Corporation, corporation: f) })
            end

            h(:div, children.compact)
          end
        end
      end
    end
  end
end
