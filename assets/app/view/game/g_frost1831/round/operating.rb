# frozen_string_literal: true

require 'view/game/round/operating'
require 'view/game/g_frost1831/influence_choice'

module View
  module Game
    module GFrost1831
      module Round
        # Operating round view for Frost 1831. Reuses the generic operating round
        # and only customises the Frost-specific bits: the influence-choice chooser,
        # hiding the corporation card during an influence choice, and the faction
        # action-cost table shown next to a faction.
        class Operating < View::Game::Round::Operating
          def choose_view
            return InfluenceChoice if @game.pending_influence_choice || @game.pre_turmoil_window

            super
          end

          def render_operating_corporation?
            !@game.pending_influence_choice
          end

          def extra_entity_views(entity)
            return [] unless entity.type == :faction

            [render_faction_cost_table]
          end

          def render_faction_cost_table
            header, *rows = @game.faction_action_cost_chart

            table_rows = rows.map do |r|
              h('tr.hover_row', [
                h(:td, r[0]),
                h('td.padded_number', r[1]),
              ])
            end

            h(:table, { style: { margin: '1rem 0' } }, [
              h(:thead, [
                h(:tr, [
                  h(:th, header[0]),
                  h(:th, header[1]),
                ]),
              ]),
              h(:tbody, table_rows),
            ])
          end
        end
      end
    end
  end
end
