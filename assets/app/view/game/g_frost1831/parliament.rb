# frozen_string_literal: true

require 'lib/settings'
require 'view/game/corporation'
require 'view/game/g_frost1831/influence_arena'
require 'view/game/market_regulation'

module View
  module Game
    module GFrost1831
      class Parliament < Snabberb::Component
        include Lib::Settings

        needs :game

        def render
          h('div#game_info', [
            render_header,
            render_arena,
            h(MarketRegulation, game: @game),
            render_turmoils,
          ])
        end

        private

        def render_header
          h(:h2, "New London's Parliament")
        end

        def render_arena
          h(:div, { style: { marginBottom: '1rem', overflowX: 'auto' } }, [
            h(InfluenceArena, game: @game, scale: 1.0),
          ])
        end

        def render_turmoils
          h(:div, { style: { marginBottom: '1rem' } }, [
            h(:h3, 'Turmoils'),
            h(:div, { style: { overflowX: 'auto' } }, [
              h(:table, [
                h(:thead, [
                  h(:tr, [
                    h(:th, ''),
                    h(:th, 'Level 1'),
                    h(:th, 'Level 2'),
                    h(:th, 'Level 3'),
                  ]),
                ]),
                h(:tbody, [
                  h(:tr, [
                    h(:td, { style: { fontWeight: 'bold', color: '#2e7d32' } }, 'GOVERNMENT'),
                    h(:td, 'Supporter gains value (+1→)'),
                    h(:td, 'Faction and Supporter +1 Influence'),
                    h(:td, 'Supporter receives 1 Favor'),
                  ]),
                  h(:tr, [
                    h(:td, { style: { fontWeight: 'bold', color: '#c0392b' } }, 'OPPOSITION'),
                    h(:td, 'Supporter loses value (-1←)'),
                    h(:td, 'Faction and Supporter -1 Influence'),
                    h(:td, 'Supporter loses 1 Station'),
                  ]),
                ]),
              ]),
            ]),
          ])
        end
      end
    end
  end
end
