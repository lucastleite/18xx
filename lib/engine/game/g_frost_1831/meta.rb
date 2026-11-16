# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module GFrost1831
      module Meta
        include Game::Meta

        DEV_STAGE = :alpha

        GAME_TITLE = 'Frost 1831'.freeze
        FIXTURE_DIR_NAME = 'frost_1831'

        GAME_DESIGNER = 'Alexandre Madu'.freeze
        GAME_IMPLEMENTER = 'Lucas Leite'.freeze

        GAME_INFO_URL = 'https://github.com/tobymao/18xx/wiki/Frost-1831'
        GAME_LOCATION = 'New London'.freeze
        GAME_PUBLISHER = nil
        GAME_RULES_URL = 'https://boardgamegeek.com/filepage/331178/rulebook-v0933'
        GAME_ALIASES = ['1831'].freeze

        PLAYER_RANGE = [2, 5].freeze

        OPTIONAL_RULES = [
          {
            sym: :parliamentary_intervention,
            short_name: 'Parliamentary Intervention',
            desc: "A player's 2nd corporation must support at least 1 faction not supported by their 1st",
          },
          {
            sym: :tight_regulation,
            short_name: 'Tight Regulation',
            desc: 'All 4 Market Regulation criteria begin at Tight Regulation',
          },
        ].freeze

        def self.fs_name
          @fs_name ||= 'g_frost_1831'
        end
      end
    end
  end
end
