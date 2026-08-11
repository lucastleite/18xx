# frozen_string_literal: true

require 'lib/settings'
require 'view/game/corporation'
require 'view/game/influence_arena'

module View
  module Game
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

      def render_factions
        factions = @game.corporations.select { |c| c.type == :faction }

        h(:div, { style: { marginBottom: '1rem' } }, [
          h(:h3, 'Factions'),
          h(:div, { style: { display: 'flex', flexWrap: 'wrap', gap: '0.5rem' } },
            factions.map { |f| h(Corporation, corporation: f) }),
        ])
      end

      def render_faction_value_track(factions)
        # Horizontal ruler showing faction values — markers sit on top
        values = %w[£70 £80 £100 £120 £140 £160 £190 £220 £250]

        track_style = {
          padding: '1rem',
          borderRadius: '8px',
          border: '1px solid #ddd',
          backgroundColor: '#fafafa',
          marginTop: '1.5rem',
        }

        header_style = {
          textAlign: 'center',
          fontSize: '0.85rem',
          fontWeight: 'bold',
          color: '#333',
          marginBottom: '0.8rem',
        }

        ruler_style = {
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-end',
          position: 'relative',
        }

        cell_style = {
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          flex: '1',
        }

        value_label_style = {
          fontSize: '0.7rem',
          fontWeight: 'bold',
          color: '#555',
          marginBottom: '4px',
          textAlign: 'center',
        }

        slot_style = {
          width: '100%',
          minHeight: '32px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'flex-end',
          gap: '2px',
          borderLeft: '1px solid #ddd',
          paddingTop: '4px',
        }

        # Currently all markers are on the first slot (£70) — initial state
        cells = values.map.with_index do |val, idx|
          tokens = []
          if idx.zero?
            factions.each do |fac|
              logo = setting_for(:simple_logos, @game) ? fac.simple_logo : fac.logo
              tokens << h(:img, { attrs: { src: logo, width: '18', height: '18' },
                                  style: { borderRadius: '50%', backgroundColor: '#444', padding: '1px',
                                           border: '1px solid #999' } })
            end
          end

          h(:div, { style: cell_style }, [
            h(:div, { style: slot_style }, tokens),
            h(:div, { style: value_label_style }, val),
          ])
        end

        h(:div, { style: track_style }, [
          h(:div, { style: header_style }, 'Faction Values in Parliament'),
          h(:div, { style: ruler_style }, cells),
        ])
      end

      def render_faction_card(fac)
        # Corporation-style card layout
        card_style = {
          borderRadius: '8px',
          overflow: 'hidden',
          border: '1px solid #ddd',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
        }

        # Colored header with logo + name
        header_style = {
          backgroundColor: fac[:color],
          padding: '0.5rem 0.8rem',
          display: 'flex',
          alignItems: 'center',
          gap: '0.6rem',
        }

        logo_circle_style = {
          width: '36px',
          height: '36px',
          borderRadius: '8px',
          backgroundColor: fac[:color],
          border: '2px solid rgba(255,255,255,0.6)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: '0',
        }

        name_style = {
          fontSize: '1rem',
          fontWeight: 'bold',
          color: '#fff',
          fontStyle: 'italic',
          textAlign: 'center',
          flex: '1',
        }

        # Gray sub-header with SYM, float info, and markers
        subheader_style = {
          backgroundColor: '#f0f0f0',
          padding: '0.5rem 0.8rem',
          borderBottom: '1px solid #ddd',
        }

        # White body
        body_style = {
          padding: '0.6rem 0.8rem',
          backgroundColor: '#fff',
          fontSize: '0.85rem',
          color: '#333',
        }

        # Base markers: 1 Base (free, placed on foundation) + 3 additional (cost 5 influence each)
        markers = []
        markers << render_marker_token(fac, 'Base')
        3.times { markers << render_marker_token(fac, '5◆') }

        # Logo path respects simple_logos setting
        logo_path = if setting_for(:simple_logos, @game)
                      "/logos/frost_1831/#{fac[:sym]}.alt.svg"
                    else
                      "/logos/frost_1831/#{fac[:sym]}.svg"
                    end

        h(:div, { style: card_style }, [
          # Header
          h(:div, { style: header_style }, [
            h(:div, { style: logo_circle_style }, [
              h(:img, { attrs: { src: logo_path, width: '28', height: '28' } }),
            ]),
            h(:span, { style: name_style }, fac[:name]),
          ]),
          # Gray sub-header: SYM | float | markers
          h(:div, { style: subheader_style }, [
            h(:div, { style: { display: 'flex', alignItems: 'center', gap: '0.6rem' } }, [
              h(:div, { style: { fontWeight: '900', fontSize: '1.5rem', lineHeight: '1' } }, fac[:sym]),
              h(:div, { style: { flex: '1', fontSize: '0.85rem', color: '#555', textAlign: 'center' } }, '40% to float'),
              h(:div, { style: { display: 'flex', flexWrap: 'nowrap', gap: '3px', alignItems: 'flex-start' } }, markers),
            ]),
          ]),
          # Body: shareholder table + info
          h(:div, { style: body_style }, [
            h(:table, { style: { width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem', marginBottom: '0.4rem' } }, [
              h(:thead, [
                h(:tr, [
                  h(:th, { style: { textAlign: 'left', fontWeight: 'bold', padding: '2px 4px' } }, 'Shareholder'),
                  h(:th, { style: { textAlign: 'center', fontWeight: 'bold', padding: '2px 4px' } }, 'Shares'),
                  h(:th, { style: { textAlign: 'center', fontWeight: 'bold', padding: '2px 4px' } }, 'Price'),
                ]),
              ]),
              h(:tbody, [
                h(:tr, [
                  h(:td, { style: { textAlign: 'left', padding: '2px 4px' } }, 'IPO'),
                  h(:td, { style: { textAlign: 'center', padding: '2px 4px' } }, '5'),
                  h(:td, { style: { textAlign: 'center', padding: '2px 4px' } }, '£70'),
                ]),
              ]),
            ]),
            h(:div, { style: { fontSize: '0.8rem', color: '#555', marginBottom: '0.2rem' } },
              "Path: #{fac[:path]} • Opposition: #{fac[:opp]}"),
            h(:div, { style: { fontSize: '0.8rem', color: '#555', marginBottom: '0.2rem' } },
              "Influence: #{@game.faction_influence(fac[:sym])}/#{@game.faction_influence_limit}"),
            h(:div, { style: { fontSize: '0.8rem', color: '#555' } },
              'Favors: 8/8'),
          ]),
        ])
      end

      def render_marker_token(fac, cost_label)
        wrapper_style = {
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }

        token_style = {
          width: '22px',
          height: '22px',
          borderRadius: '50%',
          backgroundColor: fac[:color],
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          overflow: 'hidden',
        }

        cost_style = {
          fontSize: '0.55rem',
          color: '#555',
          marginTop: '1px',
          fontWeight: 'bold',
        }

        # Respect simple_logos toggle
        marker_logo = if setting_for(:simple_logos, @game)
                        "/logos/frost_1831/#{fac[:sym]}.alt.svg"
                      else
                        "/logos/frost_1831/#{fac[:sym]}.svg"
                      end

        h(:div, { style: wrapper_style }, [
          h(:div, { style: token_style }, [
            h(:img, { attrs: { src: marker_logo, width: '16', height: '16' } }),
          ]),
          h(:div, { style: cost_style }, cost_label),
        ])
      end

    end
  end
end
