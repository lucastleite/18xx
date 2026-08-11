# frozen_string_literal: true

module Engine
  module Game
    module GFrost1831
      module ParliamentMovement
        # Parliament Arena movement table
        #
        # 29 valid positions on the grid (7 per faction territory + 1 center)
        # Center position: (3,4) — neutral / crown
        # Government marker starts here.
        #
        # Format: 'row,col' => ['gua_dest', 'tec_dest', 'lor_dest', 'exp_dest']
        # All movements are deterministic (no ambiguous choices).
        #
        # When dest equals the current position, the marker doesn't move
        # (already at maximum for that faction direction).
        #
        # Order: [GUA, TEC, LOR, EXP]

        MOVEMENTS = {
          # === CENTER (level 0) ===
          '3,4' => ['5,4', '2,3', '2,4', '5,3'],

          # === TEC territory ===
          '0,1' => ['2,3', '0,1', '0,3', '3,0'],
          '0,3' => ['2,3', '0,1', '0,4', '0,1'],
          '1,2' => ['3,4', '0,1', '1,3', '3,1'],
          '1,3' => ['3,4', '0,3', '1,4', '1,2'],
          '2,3' => ['5,4', '1,2', '2,4', '5,3'],
          '3,0' => ['2,3', '0,1', '0,1', '4,0'],
          '3,1' => ['3,4', '3,0', '1,2', '4,1'],

          # === LOR territory ===
          '0,4' => ['0,6', '0,3', '0,6', '2,4'],
          '0,6' => ['3,7', '0,4', '0,6', '2,4'],
          '1,4' => ['1,5', '1,3', '0,4', '3,4'],
          '1,5' => ['3,6', '1,4', '0,6', '3,4'],
          '2,4' => ['5,4', '2,3', '1,5', '5,3'],
          '3,6' => ['4,6', '1,5', '3,7', '3,4'],
          '3,7' => ['4,7', '0,6', '0,6', '2,4'],

          # === EXP territory ===
          '4,0' => ['7,1', '3,0', '5,3', '7,1'],
          '4,1' => ['6,2', '3,1', '3,4', '4,0'],
          '5,3' => ['5,4', '2,3', '2,4', '6,2'],
          '6,2' => ['6,3', '4,1', '3,4', '7,1'],
          '6,3' => ['6,4', '6,2', '3,4', '7,3'],
          '7,1' => ['7,3', '4,0', '5,3', '7,1'],
          '7,3' => ['7,4', '7,1', '5,3', '7,1'],

          # === GUA territory ===
          '4,6' => ['4,7', '3,4', '3,6', '6,5'],
          '4,7' => ['7,6', '5,4', '3,7', '7,6'],
          '5,4' => ['6,5', '2,3', '2,4', '5,3'],
          '6,4' => ['7,4', '3,4', '6,5', '6,3'],
          '6,5' => ['7,6', '3,4', '4,6', '6,4'],
          '7,4' => ['7,6', '5,4', '7,6', '7,3'],
          '7,6' => ['7,6', '5,4', '4,7', '7,4'],
        }.freeze

        FACTION_INDEX = { 'GUA' => 0, 'TEC' => 1, 'LOR' => 2, 'EXP' => 3 }.freeze

        def self.move(from_row, from_col, faction_sym)
          key = "#{from_row},#{from_col}"
          entry = MOVEMENTS[key]
          return nil unless entry

          idx = FACTION_INDEX[faction_sym]
          return nil unless idx

          dest = entry[idx]
          dest.split(',').map(&:to_i)
        end

        def self.valid_position?(row, col)
          MOVEMENTS.key?("#{row},#{col}")
        end

        def self.all_positions
          MOVEMENTS.keys.map { |k| k.split(',').map(&:to_i) }
        end

        # Polarization level: 0 = neutral, 1/2/3 = increasing distance from center
        POSITION_LEVELS = {
          # Center
          '3,4' => 0,
          # Level 1 (adjacent to center, one per faction)
          '2,3' => 1, # TEC
          '2,4' => 1, # LOR
          '5,3' => 1, # EXP
          '5,4' => 1, # GUA
          # Level 2 (intermediate)
          '1,2' => 2, '1,3' => 2, '3,1' => 2,       # TEC
          '1,4' => 2, '1,5' => 2, '3,6' => 2,       # LOR
          '4,1' => 2, '6,2' => 2, '6,3' => 2,       # EXP
          '4,6' => 2, '6,5' => 2, '6,4' => 2,       # GUA
          # Level 3 (extremes)
          '0,1' => 3, '0,3' => 3, '3,0' => 3,       # TEC
          '0,4' => 3, '0,6' => 3, '3,7' => 3,       # LOR
          '4,0' => 3, '7,1' => 3, '7,3' => 3,       # EXP
          '4,7' => 3, '7,4' => 3, '7,6' => 3,       # GUA
        }.freeze

        def self.polarization_level(row, col)
          POSITION_LEVELS["#{row},#{col}"] || 0
        end
      end
    end
  end
end
