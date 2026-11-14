# frozen_string_literal: true

require 'view/game/corporation'

module View
  module Game
    module GFrost1831
      class VotingFactions < Snabberb::Component
        needs :game

        def render
          cards = @game.faction_voting_order.map { |faction| h(View::Game::Corporation, corporation: faction) }
          h(:div, { style: { display: 'flex', flexWrap: 'wrap', gap: '0.5rem', marginTop: '1rem' } }, cards)
        end
      end
    end
  end
end
