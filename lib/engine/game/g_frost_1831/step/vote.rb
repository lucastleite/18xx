# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Vote < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          PASS = 'pass'
          VERBS = { 'Loose' => 'Loosen', 'Normal' => 'Normalize', 'Tight' => 'Tighten' }.freeze

          def actions(entity)
            return [] if !active? || entity != voter

            ACTIONS
          end

          def active?
            !@game.voting_regulation.nil?
          end

          def blocking?
            active?
          end

          def active_entities
            [voter]
          end

          def description
            "Vote on #{@game.regulation_label(regulation)}"
          end

          def choice_available?(entity)
            entity == voter
          end

          def choice_name
            "#{@game.regulation_title(regulation)} Vote"
          end

          def choices
            return moves(0) if @game.free_vote?

            choices = @game.faction_influence(voter.id).positive? ? moves(1) : {}
            choices.merge(PASS => 'Maintain (0◆)')
          end

          def choice_view
            :market_regulation
          end

          def auto_actions(entity)
            return if @game.free_vote? || @game.can_vote?(entity)

            [Engine::Action::Choose.new(entity, choice: PASS)]
          end

          def process_choose(action)
            return @game.pass_vote!(voter) if action.choice == PASS && !@game.free_vote?

            @game.vote_regulation!(voter, action.choice)
          end

          private

          def moves(cost)
            @game.regulation_moves(regulation).to_h { |setting| [setting, "#{VERBS[setting]} (#{cost}◆)"] }
          end

          def voter
            @game.voter
          end

          def regulation
            @game.voting_regulation
          end
        end
      end
    end
  end
end
