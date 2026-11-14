# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class FactionDividend < Engine::Step::Base
          def actions(_entity)
            []
          end

          def description
            'Faction Dividends'
          end

          def skip!
            @game.pay_faction_dividend!(current_entity)
            pass!
          end
        end
      end
    end
  end
end
