# frozen_string_literal: true

require 'view/game/actionable'
require 'lib/settings'
require 'view/game/corporation'
require 'view/game/influence_arena'

module View
  module Game
    class InfluenceChoice < Snabberb::Component
      include Actionable
      include Lib::Settings

      def render
        step = @game.round.active_step
        entity = step.active_entities.first
        choices = step.choices

        children = []
        children << render_header(step)
        children << render_faction_cards(choices, entity)
        children << h(InfluenceArena, game: @game, scale: 0.67)
        children << h(Corporation, corporation: entity) if entity.corporation?

        # Width 100% so it expands on small screens
        h(:div, { style: { display: 'flex', flexDirection: 'column', gap: '0.8rem', width: '100%' } }, children)
      end

      private

      def render_header(step)
        # No bold - consistent with other choice screens
        h(:div, { style: { fontSize: '1rem' } }, step.choice_name)
      end

      def render_faction_cards(choices, entity)
        # Check if choices are simple faction IDs (TEC, GUA, etc.) or compound (OE:TEC, faction:TEC)
        simple_faction_choices = choices.keys.all? { |k| %w[TEC GUA EXP LOR].include?(k) }

        if simple_faction_choices
          # Original behavior: render faction logos as clickable
          cards = choices.map do |faction_sym, _faction_name|
            faction_entity = @game.corporations.find { |c| c.id == faction_sym }
            next unless faction_entity

            render_clickable_faction(faction_entity, faction_sym, entity)
          end.compact

          h(:div, { style: { display: 'flex', gap: '1rem', alignItems: 'center',
                             marginBottom: '0.3rem' } }, cards)
        else
          # Compound choices (PreTurmoilInfluence): render buttons with labels
          buttons = choices.map do |choice_key, choice_label|
            click = lambda do
              process_action(Engine::Action::Choose.new(entity, choice: choice_key))
            end

            h('button', { on: { click: click }, style: { margin: '0.2rem' } }, choice_label)
          end

          h(:div, { style: { display: 'flex', flexWrap: 'wrap', gap: '0.5rem',
                             marginBottom: '0.3rem' } }, buttons)
        end
      end

      def render_clickable_faction(faction_entity, faction_sym, entity)
        click = lambda do
          process_action(Engine::Action::Choose.new(entity, choice: faction_sym))
        end

        logo = setting_for(:simple_logos, @game) ? faction_entity.simple_logo : faction_entity.logo

        h(:img, { attrs: { src: logo, width: '48', height: '48', title: faction_entity.id },
                  style: { cursor: 'pointer' },
                  on: { click: click } })
      end
    end
  end
end
