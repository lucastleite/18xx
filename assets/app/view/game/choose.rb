# frozen_string_literal: true

require 'view/game/actionable'
require 'view/game/influence_arena'
require 'view/game/market_regulation'
require 'lib/settings'

module View
  module Game
    class Choose < Snabberb::Component
      include Actionable
      include Lib::Settings

      needs :entity, default: nil

      def render
        step = @game.round.active_step
        return '' if step.respond_to?(:render_choices?) && !step.render_choices?

        choices = if step.respond_to?(:entity_choices)
                    step.entity_choices(@entity)
                  else
                    step.choices
                  end

        choice_is_amount = if step.respond_to?(:choice_is_amount?)
                             step.choice_is_amount?
                           else
                             false
                           end

        return render_choice_amount(choices) if choice_is_amount

        # Check if we should use faction icons instead of buttons
        use_icons = step.respond_to?(:use_faction_icons?) && step.use_faction_icons?

        children = []

        # Header text (without bold for consistency)
        if step.choice_name
          children << h(:div, { style: { marginTop: '0.5rem', marginBottom: '0.3rem' } }, step.choice_name)
        end

        # Render choices as icons or buttons
        if use_icons
          children << render_faction_icons(choices)
        else
          children << render_choice_buttons(choices)
        end

        if step.respond_to?(:choice_explanation) && (explanation = step.choice_explanation)
          paragraphs = explanation.map { |text_block| h(:p, text_block) }
          children << h(:div, { style: { marginTop: '0.5rem' } }, paragraphs)
        end

        # Show mini arena if step requests it (e.g., ChooseFactions in Frost 1831)
        if step.respond_to?(:show_arena?) && step.show_arena?
          children << h(InfluenceArena, game: @game, scale: 0.67)
        end

        # Show market regulation if step requests it (e.g., ChoosePriorityFaction)
        if step.respond_to?(:show_market_regulation?) && step.show_market_regulation? &&
           @game.respond_to?(:regulations)
          children << h(MarketRegulation, game: @game)
        end

        h(:div, children)
      end

      def render_choice_buttons(choices)
        buttons = choices.map do |choice, label|
          label ||= choice
          process_choose = lambda do
            choose = lambda do
              process_action(Engine::Action::Choose.new(
                @game.current_entity,
                choice: choice,
              ))
            end

            if (consenter = @game.consenter_for_choice(@game.current_entity, choice, label))
              check_consent(@game.current_entity, consenter, choose)
            else
              choose.call
            end
          end

          props = {
            style: {
              padding: '0.2rem 0.2rem',
            },
            on: { click: process_choose },
          }
          h('button', props, label)
        end

        h(:div, buttons)
      end

      def render_faction_icons(choices)
        icons = choices.map do |choice, _label|
          faction = @game.corporations.find { |c| c.id == choice }
          next unless faction

          process_choose = lambda do
            process_action(Engine::Action::Choose.new(
              @game.current_entity,
              choice: choice,
            ))
          end

          logo = setting_for(:simple_logos, @game) ? faction.simple_logo : faction.logo

          h(:img, {
            attrs: { src: logo, width: '48', height: '48', title: faction.name },
            style: { cursor: 'pointer', marginRight: '0.5rem' },
            on: { click: process_choose },
          })
        end.compact

        h(:div, { style: { display: 'flex', gap: '0.5rem', marginBottom: '0.5rem' } }, icons)
      end

      def render_choice_amount(amounts)
        min, max = amounts

        input = h('input.no_margin',
                  style: {
                    height: '1.6rem',
                    width: '4rem',
                    padding: '0 0 0 0.2rem',
                  },
                  attrs: {
                    type: 'number',
                    min: min,
                    max: max,
                    value: min,
                    size: max.to_s.size + 2,
                  })

        click = lambda do
          amount = input.JS['elm'].JS['value'].to_i
          process_action(Engine::Action::Choose.new(
                           @game.current_entity,
                           choice: amount
                         ))
        end

        h(:div,
          [
            h('div.inline',
              { style: { marginTop: '0.5rem' } },
              [
                h('span', "#{@game.round.active_step.choice_name}: "),
                input,
                h('button', { style: { padding: '0.2rem 0.2rem' }, on: { click: click } }, 'Transfer'),
              ]),
          ])
      end
    end
  end
end
