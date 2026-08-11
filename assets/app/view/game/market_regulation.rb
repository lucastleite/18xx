# frozen_string_literal: true

require 'lib/settings'

module View
  module Game
    class MarketRegulation < Snabberb::Component
      include Lib::Settings

      needs :game

      REG_DATA = {
        'R1' => { name: 'R1. Track Laying', loose: '£0 + £0', normal: '£0 + £20', tight: '£20 + £20' },
        'R2' => { name: 'R2. Track Upgrade', loose: '£0 any', normal: '£20 plain / £0 city',
                  tight: '£20 any' },
        'R3' => { name: 'R3. Corp Limit', loose: '70%', normal: '60%',
                  tight: '50%' },
        'R4' => { name: 'R4. Favor', loose: '-2 / -2 / -3', normal: '-2 / -3 / -4',
                  tight: '-3 / -4 / -4' },
      }.freeze

      def render
        regulations = @game.regulations

        h(:div, { style: { marginBottom: '1rem' } }, [
          h(:h3, 'Market Regulation'),
          h(:div, { style: { overflowX: 'auto' } }, [
            h(:table, [
              h(:thead, [
                h(:tr, [
                  h(:th, 'Criterion'),
                  h(:th, 'Loose'),
                  h(:th, 'Normal'),
                  h(:th, 'Tight'),
                ]),
              ]),
              h(:tbody, REG_DATA.map { |reg_id, data| render_row(regulations, reg_id, data) }),
            ]),
          ]),
        ])
      end

      private

      def render_row(regulations, reg_id, data)
        reg = regulations[reg_id]
        position = reg[:position]
        locked = reg[:locked]

        name_display = locked ? "#{data[:name]} 🔒" : data[:name]

        h(:tr, [
          h(:td, { style: { fontWeight: 'bold' } }, name_display),
          render_cell(data[:loose], position == 0),
          render_cell(data[:normal], position == 1),
          render_cell(data[:tight], position == 2),
        ])
      end

      def render_cell(text, active)
        style = active ? { border: '2px solid #4a90d9', fontWeight: 'bold' } : {}

        content = if active
                    h(:div, { style: { display: 'flex', alignItems: 'center', justifyContent: 'center' } }, [
                      h(:span, { style: { flex: '1', textAlign: 'center' } }, text),
                      h(:img, { attrs: { src: '/icons/frost_1831/hammer.svg', width: '20', height: '20' },
                                style: { marginLeft: '6px', marginRight: '6px' } }),
                    ])
                  else
                    text
                  end

        h(:td, { style: style }, [content])
      end
    end
  end
end
