# frozen_string_literal: true

require 'view/game/actionable'
require 'view/game/corporation'
require 'view/game/stock_market'

module View
  module Game
    module Round
      class Favor < Snabberb::Component
        include Actionable

        needs :game, store: true
        needs :selected_favor_faction, default: nil, store: true

        def render
          round = @game.round
          corporation = round.respond_to?(:current_operator) ? round.current_operator : nil
          favor_company = @game.favor_company
          @forced = corporation && @game.favors_used_this_or(corporation) >= 1 &&
                    @game.must_buy_train?(corporation) &&
                    corporation.cash < @game.cheapest_depot_train_price

          children = []

          # Cancel button (hidden in forced mode)
          children << render_cancel_button(favor_company) unless @forced

          # Info text for forced mode
          if @forced
            children << h(:div, { style: { fontWeight: 'bold', color: '#c62828', marginBottom: '0.5rem' } },
                          "Forced Favor — #{corporation.name} must buy a train "\
                          "(#{@game.format_currency(@game.cheapest_depot_train_price)})")
          end

          # Stock Market
          children << h(:div, { style: { marginTop: '1rem' } }, [
            h(StockMarket, game: @game, show_bank: false),
          ])

          # Faction cards with action buttons
          children << render_faction_cards(corporation)

          # Corporation card
          if corporation
            children << h(:div, { style: { marginTop: '1rem' } }, [
              h(Corporation, corporation: corporation, interactive: false, selectable: false),
            ])
          end

          h(:div, children)
        end

        def render_faction_cards(corporation)
          factions = @game.available_favor_factions(corporation)

          h(:div, { style: { display: 'flex', flexWrap: 'wrap', gap: '0.5rem', marginTop: '1rem' } },
            factions.map { |f| render_faction_with_buttons(f, corporation) })
        end

        def render_faction_with_buttons(faction, corporation)
          selected = @selected_favor_faction == faction.id

          select_faction = lambda do
            store(:selected_favor_faction, selected ? nil : faction.id)
          end

          children = [
            h(:div, { style: { cursor: 'pointer' }, on: { click: select_faction } }, [
              h(Corporation, corporation: faction, interactive: false, selectable: false),
            ]),
          ]

          # Show buttons only below selected faction
          children << render_type_buttons(faction, corporation) if selected

          h(:div, children)
        end

        def render_type_buttons(faction, corporation)
          corp_factions = @game.corporation_factions(corporation)
          corp_influence = @game.corporation_influence(corporation)
          buttons = []
          favor_company = @game.favor_company

          # On 2nd+ favor (forced), need 2+ cubes of same faction to pay with cube
          min_influence = @forced ? 2 : 1

          corp_factions.each do |faction_sym|
            next unless (corp_influence[faction_sym] || 0) >= min_influence

            penalty = @game.favor_market_penalty(corporation, faction, faction_sym)
            extra_label = @forced ? ' +1◆ extra' : ''
            btn_text = "Spend #{@game.faction_display_name(faction_sym)} Influence (←#{penalty})#{extra_label}"

            apply = lambda do
              process_action(Engine::Action::Choose.new(favor_company,
                choice: "apply:#{faction.id}:#{faction_sym}"))
            end

            buttons << h(:button, { on: { click: apply }, style: { width: '100%' } }, btn_text)
          end

          # No-influence option (always available)
          penalty_no_influence = @game.favor_market_penalty(corporation, faction, nil)
          apply_no_influence = lambda do
            process_action(Engine::Action::Choose.new(favor_company,
              choice: "apply:#{faction.id}:none"))
          end
          buttons << h(:button, { on: { click: apply_no_influence }, style: { width: '100%' } },
                       "Without spending Influence (←#{penalty_no_influence})")

          h(:div, { style: { display: 'flex', flexDirection: 'column', marginTop: '4px', marginRight: '8px' } }, buttons)
        end

        def render_cancel_button(favor_company)
          cancel = lambda do
            process_action(Engine::Action::Choose.new(favor_company, choice: 'cancel'))
          end

          h(:div, [
            h(:div, { style: { marginBottom: '0.3rem' } }, 'Choose Favor Mode:'),
            h(:div, { style: { display: 'flex', gap: '0.5rem' } }, [
              h(:button, { on: { click: cancel } }, 'Cancel Favor'),
            ]),
          ])
        end
      end
    end
  end
end
