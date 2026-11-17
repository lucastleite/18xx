# frozen_string_literal: true

require 'lib/settings'
require 'view/game/actionable'

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

        logo_choices = step.respond_to?(:logo_choices?) && step.logo_choices?

        choice_buttons = choices.map do |choice, label|
          label ||= choice
          process_choose = lambda do
            choose = lambda do
              process_action(Engine::Action::Choose.new(
                @game.current_entity,
                choice: choice,
                target: @entity,
              ))
            end

            if (consenter = @game.consenter_for_choice(@game.current_entity, choice, label))
              check_consent(@game.current_entity, consenter, choose)
            else
              choose.call
            end
          end

          if logo_choices && (corporation = @game.corporation_by_id(choice))
            next render_logo_choice(corporation, label, process_choose)
          end

          props = {
            style: {
              padding: '0.2rem 0.2rem',
            },
            on: { click: process_choose },
          }
          h('button', props, label)
        end

        children = []
        div_class = choice_buttons.size < 5 ? '.inline' : ''
        children << h("div#{div_class}", { style: { marginTop: '0.5rem' } }, "#{step.choice_name}: ") if step.choice_name
        children << h(:div, choice_buttons)
        if step.respond_to?(:choice_explanation) && (explanation = step.choice_explanation)
          paragraphs = explanation.map { |text_block| h(:p, text_block) }
          children << h(:div, { style: { marginTop: '0.5rem' } }, paragraphs)
        end
        if step.respond_to?(:choice_views)
          step.choice_views.each { |view, props| children << h(Object.const_get("View::Game::#{view}"), props) }
        end
        h(:div, children)
      end

      def render_logo_choice(corporation, label, process_choose)
        h(:img, {
            attrs: {
              src: setting_for(:simple_logos, @game) ? corporation.simple_logo : corporation.logo,
              title: label,
              width: '48',
              height: '48',
            },
            style: { cursor: 'pointer', marginRight: '0.5rem' },
            on: { click: process_choose },
          })
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
