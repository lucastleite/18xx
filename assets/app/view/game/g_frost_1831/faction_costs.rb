# frozen_string_literal: true

module View
  module Game
    module GFrost1831
      class FactionCosts < Snabberb::Component
        needs :game

        def render
          rows = @game.faction_action_costs.map do |action, cost|
            h('tr.hover_row', [h(:td, action), h('td.padded_number', cost)])
          end

          h(:table, { style: { margin: '1rem 0' } }, [
            h(:thead, [h(:tr, [h(:th, 'Action'), h(:th, 'Influence Cost')])]),
            h(:tbody, rows),
          ])
        end
      end
    end
  end
end
