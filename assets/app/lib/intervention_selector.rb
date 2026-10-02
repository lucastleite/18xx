# frozen_string_literal: true

module Lib
  class InterventionSelector
    attr_reader :hex, :x, :y, :factions

    def initialize(hex, coordinates, factions)
      @hex = hex
      @x, @y = coordinates
      @factions = factions
    end
  end
end
