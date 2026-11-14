# frozen_string_literal: true

require_relative 'first_operating_faction'

module Engine
  module Game
    module GFrost1831
      module Step
        class FirstVotingFaction < FirstOperatingFaction
          def active?
            @game.first_voting_faction_pending?
          end

          def help
            'The Government is Neutral: the Priority Deal holder chooses the first Faction to make a Proposal. '\
              'The others follow in Influence Arena order.'
          end

          def choice_name
            'Which Faction votes first?'
          end

          def process_choose(action)
            @game.choose_first_voting_faction!(action.entity, founded_faction(action.choice))
          end
        end
      end
    end
  end
end
