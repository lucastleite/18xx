# frozen_string_literal: true

require 'view/game/round/stock'
require 'view/game/corporation'
require 'view/game/map'
require 'view/game/g_frost1831/influence_choice'

module View
  module Game
    module GFrost1831
      module Round
        # Stock round view for Frost 1831. Reuses the generic stock round and only
        # customises the choose section, which can show the influence chooser or,
        # during an Intervention, the corporation plus the map for clicking.
        class Stock < View::Game::Round::Stock
          def render_choose_section(children)
            if @game.pending_influence_choice
              children << h(InfluenceChoice)
              return :halt
            elsif @game.pre_turmoil_window
              children << h(InfluenceChoice)
              return nil
            elsif @game.pending_intervention
              # Intervention during Stock Round - show the map for clicking
              children << h(Corporation, corporation: @game.pending_intervention)
              children << h(Map, game: @game)
              return :halt
            end

            super
          end
        end
      end
    end
  end
end
