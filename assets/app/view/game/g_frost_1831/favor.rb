# frozen_string_literal: true

require 'view/game/actionable'
require 'view/game/corporation'
require 'view/game/stock_market'

module View
  module Game
    module GFrost1831
      class Favor < Snabberb::Component
        include Actionable

        needs :game, store: true
        needs :corporation
        needs :selected_company, default: nil, store: true
        needs :selected_favor_faction, default: nil, store: true

        def render
          forced = @game.forced_favor?(@corporation)

          children = []
          children << render_cancel_button unless forced
          children << render_forced_notice if forced
          market = h(View::Game::StockMarket, game: @game, show_bank: false, show_price_movement: false)
          children << h(:div, { style: { marginTop: '1rem' } }, [market])
          children << render_faction_cards

          h(:div, children)
        end

        def render_cancel_button
          cancel = lambda do
            store(:selected_favor_faction, nil, skip: true)
            store(:selected_company, nil)
          end

          h(:div, { style: { marginTop: '0.5rem' } }, [h(:button, { on: { click: cancel } }, 'Cancel Favor')])
        end

        def render_forced_notice
          h(:div, { style: { fontWeight: 'bold', color: '#c62828', marginTop: '0.5rem' } },
            "Forced Favor — #{@corporation.name} must buy a train "\
            "(#{@game.format_currency(@game.cheapest_depot_train_price)})")
        end

        def render_faction_cards
          h(:div, { style: { display: 'flex', flexWrap: 'wrap', gap: '0.5rem', marginTop: '1rem' } },
            @game.available_favor_factions.map { |faction| render_faction(faction) })
        end

        def render_faction(faction)
          selected = @selected_favor_faction == faction.id
          select_faction = -> { store(:selected_favor_faction, selected ? nil : faction.id) }

          children = [
            h(:div, { style: { cursor: 'pointer' }, on: { click: select_faction } }, [
              h(View::Game::Corporation, corporation: faction, interactive: false, selectable: false),
            ]),
          ]
          children << render_favor_buttons(faction) if selected

          h(:div, children)
        end

        def render_favor_buttons(faction)
          buttons = favor_choices(faction).map do |choice, label|
            apply = lambda do
              store(:selected_favor_faction, nil, skip: true)
              process_action(Engine::Action::ChooseAbility.new(@selected_company, choice: choice))
            end

            h(:button, { on: { click: apply }, style: { width: '100%' } }, label)
          end

          h(:div, { style: { display: 'flex', flexDirection: 'column', marginTop: '4px' } }, buttons)
        end

        def favor_choices(faction)
          @game.favor_choices(@corporation).select { |choice, _| choice.start_with?("#{faction.id}:") }
        end
      end
    end
  end
end
