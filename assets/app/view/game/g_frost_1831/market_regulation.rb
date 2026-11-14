# frozen_string_literal: true

module View
  module Game
    module GFrost1831
      class MarketRegulation < Snabberb::Component
        needs :game

        CRITERIA = {
          'R1' => { name: 'R1. Track Laying', settings: ['£0 + £0', '£0 + £20', '£20 + £20'] },
          'R2' => { name: 'R2. Track Upgrade', settings: ['£0 any', '£20 plain / £0 city', '£20 any'] },
          'R3' => { name: 'R3. Corp Limit', settings: ['70%', '60%', '50%'] },
          'R4' => { name: 'R4. Favor', settings: ['-2 / -3', '-2 / -4', '-3 / -4'] },
        }.freeze

        HAMMER = '/icons/frost_1831/hammer.svg'

        def render
          header = h(:tr, [h(:th, 'Criterion'), *@game.class::REGULATION_SETTINGS.map { |setting| h(:th, setting) }])

          h(:div, { style: { marginBottom: '1rem' } }, [
            h(:h3, 'Market Regulation'),
            h(:div, { style: { overflowX: 'auto' } }, [
              h(:table, [
                h(:thead, [header]),
                h(:tbody, @game.regulations.keys.map { |regulation| render_row(regulation) }),
              ]),
            ]),
          ])
        end

        private

        def render_row(regulation)
          criterion = CRITERIA[regulation]
          name = @game.locked_regulation?(regulation) ? "#{criterion[:name]} 🔒" : criterion[:name]
          current = @game.regulation_value(regulation)

          cells = criterion[:settings].each_with_index.map { |text, index| render_cell(text, index == current) }
          h(:tr, [h(:td, { style: { fontWeight: 'bold' } }, name), *cells])
        end

        def render_cell(text, active)
          return h(:td, text) unless active

          content = h(:div, { style: { display: 'flex', alignItems: 'center', justifyContent: 'center' } }, [
            h(:span, { style: { flex: '1', textAlign: 'center' } }, text),
            h(:img, { attrs: { src: HAMMER, width: '20', height: '20' }, style: { margin: '0 6px' } }),
          ])
          h(:td, { style: { border: '2px solid #4a90d9', fontWeight: 'bold' } }, [content])
        end
      end
    end
  end
end
