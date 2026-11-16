# frozen_string_literal: true

require_relative '../../../round/stock'

module Engine
  module Game
    module GFrost1831
      module Round
        class FinalResolution < Engine::Round::Stock
          def self.short_name
            'Final'
          end

          def name
            'Final Resolution'
          end

          def setup; end

          def after_process(_action); end

          def finished?
            !active_step
          end

          def show_auto?
            false
          end
        end
      end
    end
  end
end
