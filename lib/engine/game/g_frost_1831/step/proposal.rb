# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Proposal < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          PASS = 'pass'

          def actions(entity)
            return [] if !active? || entity != proposer

            ACTIONS
          end

          def active?
            @game.proposal_pending?
          end

          def blocking?
            active?
          end

          def active_entities
            [proposer]
          end

          def description
            'Make a Proposal'
          end

          def choice_available?(entity)
            entity == proposer
          end

          def choice_name
            'Criterion'
          end

          def choices
            choices = @game.available_regulations.to_h do |regulation|
              [regulation, @game.regulation_title(regulation)]
            end
            choices.merge(PASS => 'Pass')
          end

          def choice_view
            :market_regulation
          end

          def process_choose(action)
            return @game.pass_proposal!(proposer) if action.choice == PASS

            @game.propose_regulation!(proposer, action.choice)
          end

          private

          def proposer
            @game.proposer
          end
        end
      end
    end
  end
end
