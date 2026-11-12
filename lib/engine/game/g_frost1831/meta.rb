# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module GFrost1831
      module Meta
        include Game::Meta

        DEV_STAGE = :alpha

        GAME_TITLE = 'Frost 1831'.freeze
        GAME_ISSUE_LABEL = 'frost1831'
        FIXTURE_DIR_NAME = 'frost1831'

        GAME_DESIGNER = 'Alexandre Madu'.freeze
        GAME_IMPLEMENTER = 'Lucas Leite'.freeze

        GAME_INFO_URL = nil
        GAME_LOCATION = 'New London'.freeze
        GAME_PUBLISHER = nil
        GAME_RULES_URL = 'https://boardgamegeek.com/filepage/331178/rulebook-v0933'
        GAME_ALIASES = ['1831'].freeze

        PLAYER_RANGE = [2, 5].freeze

        OPTIONAL_RULES = [
          {
            sym: :parliamentary_intervention,
            short_name: 'Parliamentary Intervention',
            desc: "Player's 2nd corporation must support at least 1 faction different from the 1st corporation",
          },
          {
            sym: :tight_government,
            short_name: 'Tight Government',
            desc: 'All regulations start at Tight position (R1-R4 = 2)',
          },
        ].freeze
      end
    end
  end
end
