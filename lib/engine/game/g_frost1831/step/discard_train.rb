# frozen_string_literal: true

require_relative '../../../step/discard_train'

module Engine
  module Game
    module GFrost1831
      module Step
        class DiscardTrain < Engine::Step::DiscardTrain
          def process_discard_train(action)
            train = action.train
            # Frost 1831: discarded trains are removed from the game, not sent to bank pool
            @game.discard_train(train)
          end
        end
      end
    end
  end
end
