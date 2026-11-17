# frozen_string_literal: true

require_relative '../../operating_info'
require_relative 'meta'
require_relative 'parliament_movement'
require_relative 'map'
require_relative 'entities'
require_relative 'faction'
require_relative 'tiles'
require_relative 'stock_market'
require_relative 'round/stock'
require_relative 'round/operating'
require_relative 'round/voting'
require_relative 'round/final_resolution'
require_relative 'step/buy_sell_par_shares'
require_relative 'step/choose_factions'
require_relative 'step/choose_influence'
require_relative 'step/track'
require_relative 'step/home_token'
require_relative 'step/token'
require_relative 'step/intervention'
require_relative 'step/pre_turmoil_influence'
require_relative 'step/turmoil_station_loss'
require_relative 'step/first_operating_faction'
require_relative 'step/first_voting_faction'
require_relative 'step/proposal'
require_relative 'step/vote'
require_relative 'step/faction_action'
require_relative 'step/faction_dividend'
require_relative 'step/exchange'
require_relative 'step/special_choose'
require_relative 'step/favor'
require_relative 'step/buy_train'
require_relative 'step/buy_cert'
require_relative 'step/dividend'
require_relative 'step/special_track'
require_relative '../base'

module Engine
  module Game
    module GFrost1831
      class Game < Game::Base
        include_meta(GFrost1831::Meta)
        include Entities
        include Map
        include Tiles

        CURRENCY_FORMAT_STR = '£%s'

        BANK_CASH = 9000

        STARTING_CASH = { 2 => 1200, 3 => 800, 4 => 600, 5 => 480 }.freeze

        CAPITALIZATION = :full

        MUST_SELL_IN_BLOCKS = false

        SELL_BUY_ORDER = :sell_buy

        EBUY_CAN_SELL_SHARES = false

        CONVOY = 'PCO'

        FACTION_CHOICE = 'faction'

        TILE_LAYS = [
          { lay: true, upgrade: true },
          { lay: :not_if_upgraded, upgrade: false },
        ].freeze

        GAME_END_CHECK = { bank: :full_or }.freeze

        EBUY_OWNER_MUST_HELP = false

        MUST_EMERGENCY_ISSUE_BEFORE_EBUY = false

        # Rusted/discarded trains are removed from the game, not sent to bank pool
        DISCARDED_TRAINS = :remove

        CERT_LIMIT = {
          2 => { 8 => 31, 7 => 27, 6 => 25, 5 => 22 },
          3 => { 8 => 25, 7 => 22, 6 => 20, 5 => 18 },
          4 => { 8 => 22, 7 => 20, 6 => 18, 5 => 16 },
          5 => { 8 => 19, 7 => 17, 6 => 15, 5 => 14 },
        }.freeze

        MARKET = [
          %w[0B,arrow:none 70B,arrow:down 80B,arrow:down 90B,arrow:down 100B,arrow:down 110B,arrow:down
             120B,arrow:down 140B,arrow:down 160B,arrow:down 190B,arrow:down 220B,arrow:down 250B,arrow:down
             300B,arrow:down],
          %w[0c,arrow:none 70y 80 90 100p 110 120 140 160 190 220 250 300W 300B,arrow:left],
          %w[0c,arrow:none 60y 70 80 90p 100 110 130 150 180 210 240W],
          %w[0c,arrow:none 50y 60 70 80p 90 100 120 140 170 200W],
          %w[0c,arrow:none 40y 50 60 70p 80 90 110 130 160W],
          %w[0c,arrow:none 30y 40 50 60p 70 80 100 120W],
          %w[0c,arrow:none 20y 30 40 50 60 70 80W],
          %w[0c,arrow:none 10y 20 30 40 50 60W],
          %w[0c,arrow:none 0c,arrow:none],
          %w[70r 80r 100r 120r 140r 160r 190r 220r 250r,arrow:none],
        ].freeze

        FACTION_ROW = 9

        FACTION_START_PRICE = 70

        FACTION_RESERVED_CITIES = %w[F3 G8 K14 M8].freeze

        STOCKMARKET_COLORS = Base::STOCKMARKET_COLORS.merge(
          close: :orange,
          pays_bonus: :purple,
          pays_bonus_1: :blue,
          repar: :gray,
        ).freeze

        MARKET_TEXT = Base::MARKET_TEXT.merge(
          par: 'Initial Offering (£60–£100)',
          close: 'Intervention Zone — apply consequences',
          pays_bonus: 'Influence Zone — grants Influence',
          pays_bonus_1: 'Influence — first to reach',
          no_cert_limit: 'Shares do not count towards cert limit, may hold >60%',
          repar: 'Faction Values in Parliament',
        ).freeze

        PHASES = [
          {
            name: '2',
            on: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: %w[can_buy_companies parliament_opens],
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: %w[can_buy_companies turmoil],
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['blizzard'],
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['turmoil'],
          },
          {
            name: 'D',
            on: 'D',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 3,
            status: ['turmoil'],
          },
        ].freeze

        TRAINS = [
          {
            name: '2',
            distance: 2,
            price: 80,
            rusts_on: '4',
            num: 8,
          },
          {
            name: '3',
            distance: 3,
            price: 180,
            rusts_on: '6',
            num: 5,
            events: [{ 'type' => 'parliament_opens' }],
          },
          {
            name: '4',
            distance: 4,
            price: 300,
            rusts_on: 'D',
            num: 4,
            events: [{ 'type' => 'turmoil' }],
          },
          {
            name: '5',
            distance: 5,
            price: 530,
            num: 3,
            events: [{ 'type' => 'blizzard' }, { 'type' => 'close_companies' }],
          },
          {
            name: '6',
            distance: 6,
            price: 630,
            num: 2,
            events: [{ 'type' => 'turmoil' }],
          },
          {
            name: 'D',
            distance: 999,
            price: 1100,
            num: 'unlimited',
            available_on: '6',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
            events: [{ 'type' => 'turmoil' }],
          },
        ].freeze

        TRAIN_NAMES = {
          '2' => 'Hope',
          '3' => 'Long John',
          '4' => 'Ice Breaker',
          '5' => 'The Queen',
          '6' => 'Nightmare',
          'D' => 'Silver Bullet',
        }.freeze

        EVENTS_TEXT = Base::EVENTS_TEXT.merge(
          'parliament_opens' => ['Parliament Opens', 'Factions become available in the next Stock Round'],
          'turmoil' => ['Turmoil', 'Political turmoil — consequences depend on Parliament state'],
          'blizzard' => ['Blizzard', 'Yellow tiles on marked hexes are removed; isolated stations are eliminated'],
        ).freeze

        STATUS_TEXT = Base::STATUS_TEXT.merge(
          'parliament_opens' => ['Parliament Opens', 'Factions are available for purchase'],
          'turmoil' => ['Turmoil', 'Political turmoil triggered'],
          'blizzard' => ['Blizzard', 'Blizzard event active — marked yellow tiles removed'],
        ).freeze

        FACTION_NAMES = {
          'TEC' => 'Technicians',
          'GUA' => 'Guardians',
          'EXP' => 'Expansionists',
          'LOR' => 'Lords',
        }.freeze

        FACTION_ORDER = %w[TEC LOR GUA EXP].freeze

        OPPOSITES = {
          'TEC' => 'GUA',
          'GUA' => 'TEC',
          'EXP' => 'LOR',
          'LOR' => 'EXP',
        }.freeze

        GOVERNMENT_START = [3, 4].freeze

        GOVERNMENT_NEUTRAL_LINES = [3, 4].freeze

        GOVERNMENT_QUADRANTS = {
          [true, true] => 'TEC',
          [true, false] => 'LOR',
          [false, true] => 'EXP',
          [false, false] => 'GUA',
        }.freeze

        GOVERNMENT_MIDDLE = 4

        SECOND_SUPPORT_SET_FLOAT = 4

        CORPORATION_INFLUENCE_LIMITS = { '2' => 3, '3' => 4, '4' => 4, '5' => 5, '6' => 5, 'D' => 5 }.freeze

        FACTION_INFLUENCE_LIMITS = { '2' => 6, '3' => 6, '4' => 6, '5' => 8, '6' => 8, 'D' => 10 }.freeze

        PHASE_INFLUENCE_LIMITS = {
          '◆ Corp Limit' => CORPORATION_INFLUENCE_LIMITS,
          '◆ Faction Limit' => FACTION_INFLUENCE_LIMITS,
        }.freeze

        TURMOIL_INFLUENCE_LEVEL = 2

        TURMOIL_FAVOR_LEVEL = 3

        EXTRA_GAME_TABS = [
          { title: 'P|arliament', anchor: 'parliament', view: 'GFrost1831::Parliament', key: 'p' }.freeze,
        ].freeze

        BLIZZARD_ICON = 'blizzard'
        NEW_LONDON_LABEL = 'NL'
        NORTH_ICON = 'N'
        SOUTH_ICON = 'S'
        EAST_ICON = 'E'
        NORTH_SOUTH_BONUS = 50
        EAST_BONUS = 70
        SUPPORTER_BYPASS_MARK = '◆'

        SUPPORTER_BYPASS_CHOICE = 'diamond'
        FINAL_INFLUENCE_PER_TOKEN = 4

        BLIZZARD_SURVIVING_COLORS = %i[green brown gray].freeze

        REGULATIONS = {
          'R1' => 'Track Laying',
          'R2' => 'Track Upgrade',
          'R3' => 'Corporation Limit',
          'R4' => 'Favor',
        }.freeze

        LOOSE = 0
        NORMAL = 1
        TIGHT = 2

        REGULATION_SETTINGS = %w[Loose Normal Tight].freeze

        REGULATION_COST = 20

        R3_OWNERSHIP_LIMITS = [70, 60, 50].freeze

        MAX_FAVORS = 5

        FAVOR_AMOUNT = 100
        FAVORS_COLUMN = 'Favors'

        FAVOR_PENALTY_WITH_INFLUENCE = [2, 2, 3].freeze

        FAVOR_PENALTY_WITHOUT_INFLUENCE = [3, 4, 4].freeze

        FAVOR_WITHOUT_INFLUENCE = 'none'

        NO_CERT_LIMIT_OWNERSHIP = 100

        INFLUENCE_ICON = 'influence_cube'

        INTERVENTION_CARDS = { 2 => 2, 3 => 2, 4 => 1, 5 => 1 }.freeze

        FACTION_TILE_LAYS = [{ lay: true, upgrade: true }].freeze

        FACTION_TRACK_COSTS = { yellow: 1, green: 2, brown: 3, gray: 4 }.freeze

        FACTION_MOUNTAIN_COSTS = { 50 => 1, 80 => 2 }.freeze

        FACTION_BASE_COST = 5

        FACTION_EXCLUDED_HEXES = %w[D7 M6].freeze

        FACTION_BASE_INCOME = { '3' => 20, '4' => 20, '5' => 30, '6' => 30, 'D' => 40 }.freeze

        FACTION_INTERVENTION_CERTIFICATE_REVENUE = 10

        FACTION_INFLUENCE_REVENUE = 10

        D_TRAIN = 'D'

        INFLUENCE_REASONS = {
          blue_space: 'first to reach a blue space',
          influence_zone: 'Influence Zone',
          d_train: 'D-train purchase',
          new_london_route: 'New London Route',
        }.freeze

        # Track when bank breaks so D train doesn't override it
        def end_now?(after)
          @bank_broken_trigger ||= true if after == :full_or && @bank.broken?
          return true if @round.is_a?(GFrost1831::Round::FinalResolution)

          super
        end

        def end_game!(game_end_reason)
          return super if %i[manually_ended dnf].include?(game_end_reason)
          return if start_final_resolution!

          move_final_influence!
          convert_final_influence!
          super
        end

        def start_final_resolution!
          return false if @final_resolution

          @final_resolution = true
          @log << '-- Final Resolution --'
          @log << '-- Event: Endgame Turmoil! --'
          start_turmoil!
          return false if !@turmoil_players && !@turmoil_station_loss

          @round = GFrost1831::Round::FinalResolution.new(self, [
            GFrost1831::Step::PreTurmoilInfluence,
            GFrost1831::Step::TurmoilStationLoss,
          ])
          true
        end

        def move_final_influence!
          @corporations.reject { |c| c.type == :faction || c.closed? }.each do |corporation|
            corporation_influence(corporation).each do |faction_sym, count|
              next unless count.positive?

              @faction_influence[faction_sym] += count
              @log << "#{corporation.name} moves #{count} Influence to #{faction_display_name(faction_sym)}"
            end
            @corporation_influence[corporation.id] = {}
          end
        end

        def convert_final_influence!
          founded_factions.each do |faction|
            tokens = [(faction_influence(faction.id).to_f / self.class::FINAL_INFLUENCE_PER_TOKEN).floor,
                      faction.tokens_available].min
            next unless tokens.positive?

            influence = faction_influence(faction.id)
            tokens.times { @stock_market.move_right(faction) }
            @log << "#{faction.full_name} has #{influence} Influence and converts into #{tokens} "\
                    "token#{tokens == 1 ? '' : 's'}. #{faction.name}'s value increases to "\
                    "#{format_currency(faction.share_price.price)}"
          end
        end

        def info_train_name(train)
          thematic = self.class::TRAIN_NAMES[train.name]
          thematic ? "#{super} (#{thematic})" : super
        end

        def game_ending_description
          reason, after = game_end_check
          return if !after || reason != :bank
          return "Game ends at conclusion of OR #{@turn}.#{operating_rounds}" if @round.is_a?(Engine::Round::Operating)

          'Game ends at conclusion of the next full OR set'
        end

        def share_price_changed(entity, from)
          return if entity.share_price == from

          claim_first_to_arrive_cell(entity, entity.share_price)
          update_ownership_limit_for(entity)
        end

        def claim_first_to_arrive_cell(entity, price)
          return unless price.types.delete(:pays_bonus_1)

          @log << "#{entity.name} is first to reach #{format_currency(price.price)}"
          grant_corporation_influence!(entity, :blue_space)
        end

        def sold_out_stock_movement(corporation)
          previous = corporation.share_price
          @stock_market.move_up(corporation)
          check_influence_zone!(corporation, previous)
        end

        def log_share_price(entity, from, steps = nil, log_steps: false)
          return check_influence_zone!(entity, from) if entity.share_price != from && entity.share_price.type == :pays_bonus

          super
          share_price_changed(entity, from)
        end

        def check_influence_zone!(corporation, previous)
          return if corporation.share_price.type != :pays_bonus || corporation.type == :faction

          @stock_market.move(corporation, previous.coordinates)
          @log << "#{corporation.name} reaches the Influence Zone and returns to #{format_currency(previous.price)}"
          grant_corporation_influence!(corporation, :influence_zone)
        end

        def buy_train(operator, train, price = nil)
          d_train = train.name == self.class::D_TRAIN && train.owner == @depot
          super
          grant_corporation_influence!(operator, :d_train) if d_train
        end

        def after_lay_tile(hex, tile, entity)
          return unless new_london_route_icon(hex)

          edge_a, edge_b = hex.original_tile.future_paths.first.exits
          return unless edges_connected?(tile, edge_a, edge_b)

          hex.tile.icons.delete(new_london_route_icon(hex))
          corporation = entity.company? ? entity.owner : entity
          return grant_faction_influence!(corporation, :new_london_route, hex.name) if corporation&.type == :faction

          grant_corporation_influence!(corporation, :new_london_route, hex.name) if corporation&.corporation?
        end

        def grant_faction_influence!(faction, reason, place)
          if faction_influence_gain(faction.id)
            @log << "#{faction.name} gains 1 Influence from #{self.class::INFLUENCE_REASONS[reason]} (#{place})"
          end
          move_government(faction.id)
        end

        def supporter_bypass?(train)
          @supporter_bypass_trains.key?(train.id)
        end

        def supporter_bypass_options(corporation)
          factions = corporation_factions(corporation).select { |f| corporation_influence_for(corporation, f).positive? }
          corporation.trains.reject { |train| supporter_bypass?(train) }.uniq(&:name).product(factions)
        end

        def supporter_bypass_choice(train, faction_sym)
          "#{self.class::SUPPORTER_BYPASS_CHOICE}_#{train.id}_#{faction_sym}"
        end

        def supporter_bypass_label(faction_sym)
          "Influence by #{faction_display_name(faction_sym)}"
        end

        def supporter_bypass_choices(corporation)
          supporter_bypass_options(corporation).to_h do |train, faction_sym|
            [supporter_bypass_choice(train, faction_sym),
             "#{train.name} → #{train.name}#{self.class::SUPPORTER_BYPASS_MARK}: #{supporter_bypass_label(faction_sym)}"]
          end
        end

        def move_influence_to_train!(corporation, choice)
          available = supporter_bypass_choices(corporation).key?(choice)
          raise GameError, "#{corporation.name} cannot use that Supporter Bypass" unless available

          _, train_id, faction_sym = choice.split('_')
          train = corporation.trains.find { |t| t.id == train_id }
          @corporation_influence[corporation.id][faction_sym] -= 1
          @supporter_bypass_trains[train.id] = faction_sym
          @log << "#{corporation.name} moves 1 #{faction_display_name(faction_sym)} Influence onto a #{train.name}-train "\
                  '(Supporter Bypass)'
        end

        def trains_str(corporation)
          return super if corporation.trains.none? { |train| supporter_bypass?(train) }

          [corporation.trains.map { |train| supporter_bypass_name(train) }.join(' ')]
        end

        def supporter_bypass_name(train)
          supporter_bypass?(train) ? "#{train.name}#{self.class::SUPPORTER_BYPASS_MARK}" : train.name
        end

        def check_connected(route, corporation)
          return super unless supporter_bypass?(route.train)

          factions = corporation_factions(corporation)
          connected = route.ordered_paths.each_cons(2).all? do |a, b|
            a.connects_to?(b, corporation) || bypasses_supporter_city?(a, b, factions)
          end
          raise GameError, 'Route is not connected' unless connected
        end

        def bypasses_supporter_city?(path, next_path, factions)
          [path.a, path.b].any? do |part|
            part.city? && next_path.nodes.include?(part) &&
              part.tokens.any? { |token| token && factions.include?(token.corporation.id) }
          end
        end

        def graph_for_entity(entity)
          return super unless supporter_bypass_routes?(entity)

          @supporter_bypass_graph ||= Graph.new(self, no_blocking: true)
        end

        def supporter_bypass_routes?(entity)
          return false if @finding_route_step || !entity.corporation? || entity.trains.none? { |t| supporter_bypass?(t) }

          route_step_active?
        end

        def route_step_active?
          @finding_route_step = true
          @round.active_step.is_a?(Engine::Step::Route)
        ensure
          @finding_route_step = false
        end

        def clear_graph
          super
          @supporter_bypass_graph&.clear
        end

        def clear_graph_for_entity(entity)
          super
          @supporter_bypass_graph&.clear
        end

        def check_other(route)
          hex = route.visited_stops.map(&:hex).group_by(&:itself).find { |_, visits| visits.size > 1 }&.first
          raise GameError, "Route cannot stop twice in #{hex.name}" if hex
        end

        def revenue_for(route, stops)
          super + route_bonuses(stops).sum { |_, amount| amount }
        end

        def revenue_str(route)
          [super, *route_bonuses(route.visited_stops).map { |name, amount| "#{name}(+#{amount})" }].join(' + ')
        end

        def route_bonuses(stops)
          hexes = stops.map(&:hex)
          return [] if hexes.none? { |hex| hex.tile.label.to_s == self.class::NEW_LONDON_LABEL }

          bonuses = []
          if route_region?(hexes, self.class::NORTH_ICON) && route_region?(hexes, self.class::SOUTH_ICON)
            bonuses << ['S-NL-N', self.class::NORTH_SOUTH_BONUS]
          end
          east = hexes.count { |hex| region_hexes(self.class::EAST_ICON).include?(hex) }
          bonuses << ['NL-E', self.class::EAST_BONUS * east] if east.positive?
          bonuses
        end

        def route_region?(hexes, icon)
          hexes.intersect?(region_hexes(icon))
        end

        def region_hexes(icon)
          @region_hexes ||= {}
          @region_hexes[icon] ||= begin
            marked = @hexes.select { |hex| hex.tile.icons.any? { |i| i.name == icon } }
            groups = marked.flat_map { |hex| hex.tile.offboards.flat_map(&:groups) }
            @hexes.select { |hex| marked.include?(hex) || hex.tile.offboards.any? { |o| o.groups.intersect?(groups) } }
          end
        end

        def new_london_route_icon(hex)
          hex.tile.icons.find { |icon| icon.name == self.class::INFLUENCE_ICON }
        end

        def edges_connected?(tile, edge_a, edge_b)
          tile.paths.any? { |path| path.exits.include?(edge_a) && path.exits.include?(edge_b) } ||
            tile.nodes.any? do |node|
              exits = node.paths.flat_map(&:exits)
              exits.include?(edge_a) && exits.include?(edge_b)
            end
        end

        def grant_corporation_influence!(corporation, reason, place = nil)
          return if corporation_factions(corporation).empty?

          available = corporation_factions(corporation).select { |f| within_influence_limit?(corporation, f) }
          if available.empty?
            @log << "#{corporation.name} cannot receive influence (both factions at limit — cube discarded)"
            return
          end

          choice = { corporation: corporation, factions: available, reason: reason, place: place, moves_government: !turmoil? }
          @log << "#{corporation.name} gains 1 Influence (#{influence_reason_text(choice)})"
          @pending_influence_queue << choice
          @round&.clear_cache!
        end

        def influence_reason_text(choice)
          text = self.class::INFLUENCE_REASONS[choice[:reason]]
          choice[:place] ? "#{text}, #{choice[:place]}" : text
        end

        def pending_influence_choice
          @pending_influence_queue.first
        end

        def resolve_influence_choice!(faction_sym)
          choice = @pending_influence_queue.shift
          apply_faction_influence!(choice[:corporation], faction_sym, moves_government: choice[:moves_government])
          execute_deferred_turmoil! if choice[:reason] == :d_train
        end

        def within_influence_limit?(corporation, faction_sym)
          corporation_influence_for(corporation, faction_sym) < corporation_influence_limit
        end

        attr_reader :government_marker, :intervention, :regulations, :turmoil_station_loss, :voting_regulation

        FACTION_TREASURY = 500

        def setup
          super

          @government_marker = GOVERNMENT_START.dup
          @faction_influence = Hash.new(0)
          @parliament_open = false
          @regulations = REGULATIONS.transform_values { |name| { name: name, position: starting_regulation } }
          @locked_regulations = []
          @player_influence = Hash.new(0)

          factions.each { |faction| @bank.spend(self.class::FACTION_TREASURY, faction) }

          @faction_support_pool = faction_names.keys.flat_map { |f| [f, f] }
          @faction_support_reserve = @faction_support_pool.dup
          @corporations_floated_count = 0
          @corporation_factions = {}
          @corporation_influence = {}
          @pending_faction_choices = []
          @pending_influence_queue = []
          @deferred_turmoil = false
          @turmoil = false
          @turmoil_players = nil
          @turmoil_station_loss = nil
          @blizzard_eliminations = []
          @intervention = nil
          @first_operating_faction = nil
          @intervention_certificates = Hash.new(0)
          @intervention_cards_given = 0
          @corporations_removed = 0
          @favors_used = Hash.new(0)
          @favors_this_or = Hash.new(0)
          @supporter_bypass_trains = {}

          setup_use_influence
          setup_favor
          setup_parliament_track
          apply_r3_limits if tight_regulation?
        end

        def tight_regulation?
          @optional_rules&.include?(:tight_regulation)
        end

        def starting_regulation
          tight_regulation? ? self.class::TIGHT : self.class::NORMAL
        end

        def setup_favor
          @favor_company = Engine::Company.new(**self.class::FAVOR_COMPANY)
          @companies << @favor_company
          update_cache(:companies)
        end

        def setup_use_influence
          @use_influence = Engine::Company.new(**self.class::USE_INFLUENCE_COMPANY)
          @companies << @use_influence
          update_cache(:companies)
        end

        # Factions are not capitalized: founding one pays nothing into its Treasury
        def init_corporations(stock_market)
          min_price = stock_market.par_prices.map(&:price).min
          factions = self.class::FACTIONS.map do |faction|
            Faction.new(min_price: min_price, capitalization: :none, **faction.merge(corporation_opts))
          end
          super + factions
        end

        # Factions are bought from Parliament, never parred like Corporations
        def can_par?(corporation, parrer)
          corporation.type != :faction && super
        end

        # The certificate limit depends on the Corporations in play (8.6), not the Factions
        def init_cert_limit
          cert_limit = self.class::CERT_LIMIT[@players.size]
          corporations = @corporations.count { |c| c.type != :faction && !c.closed? }
          cert_limit.reject { |k, _| k < corporations }.min_by(&:first)&.last || cert_limit.first.last
        end

        def factions
          @corporations.select { |c| c.type == :faction }
        end

        def bank_sort(corporations)
          factions, others = corporations.partition { |c| c.type == :faction }
          super(factions) + super(others)
        end

        def show_market_row?(corporation)
          corporation.type != :faction
        end

        def player_shares_sort(player, shares_by_corporation)
          factions, others = shares_by_corporation.partition { |c, _| c.type == :faction }
          super(player, factions) + super(player, others)
        end

        def sorted_corporations
          start = faction_order.index(governing_faction_sym || @first_operating_faction) || 0
          arena = faction_order.rotate(start).map { |sym| corporation_by_id(sym) }
          floated, others = (@corporations - factions).partition(&:floated?)
          ipoed, rest = others.partition(&:ipoed)
          arena + floated.sort + ipoed.sort + rest
        end

        # Actions store a Faction's entity_type as 'faction'
        def faction_by_id(id)
          corporation_by_id(id)
        end

        def ipo_name(entity = nil)
          entity&.type == :faction ? 'Parliament' : super
        end

        def count_available_tokens(corporation)
          return super unless corporation.type == :faction

          corporation.tokens_in_parliament
        end

        def token_string(corporation)
          return super unless corporation.type == :faction

          "#{corporation.tokens_in_parliament}/#{corporation.tokens_total}"
        end

        def status_array(corporation)
          if corporation.type == :faction
            rows = [
              ["Influence: #{faction_influence(corporation.id)}/#{faction_influence_limit}", ''],
              ["Tokens: #{token_string(corporation)}", ''],
            ]
            certificates = intervention_certificates(corporation)
            rows << ["Intervention Certificates: #{certificates}", ''] if certificates.positive?
            return rows
          end

          influence = corporation_influence(corporation)
          rows = corporation_factions(corporation).map do |f|
            ["#{faction_display_name(f)}: #{influence[f] || 0}/#{corporation_influence_limit}", '']
          end
          rows << ["Favors: #{favors_used(corporation)}/#{self.class::MAX_FAVORS}", ''] if favors_used(corporation).positive?
          rows
        end

        def float_corporation(corporation)
          super
          return if corporation.type == :faction

          @pending_faction_choices << { corporation: corporation, entity: corporation.owner, step: :first }
        end

        def parliamentary_intervention?
          @optional_rules&.include?(:parliamentary_intervention)
        end

        def faction_support_available
          @faction_support_pool.uniq
        end

        def faction_support_remaining(faction_sym)
          @faction_support_pool.count(faction_sym)
        end

        def faction_support_available_for_second(first_choice)
          @faction_support_pool.uniq - [first_choice, opposite_faction(first_choice)]
        end

        def pending_faction_choice
          @pending_faction_choices.first
        end

        def choose_first_faction!(faction_sym)
          pending_faction_choice[:step] = :second
          pending_faction_choice[:first_choice] = faction_sym
        end

        def finish_faction_choice!(faction_sym)
          choice = @pending_faction_choices.shift
          support_factions!(choice[:corporation], [choice[:first_choice], faction_sym])
        end

        def consume_faction_support!(faction_sym)
          @faction_support_pool.delete_at(@faction_support_pool.index(faction_sym))
        end

        def apply_faction_influence!(corporation, faction_sym, moves_government: true)
          @corporation_factions[corporation.id] ||= []
          @corporation_factions[corporation.id] << faction_sym unless @corporation_factions[corporation.id].include?(faction_sym)

          @corporation_influence[corporation.id] ||= {}
          @corporation_influence[corporation.id][faction_sym] ||= 0

          limit = corporation_influence_limit
          if @corporation_influence[corporation.id][faction_sym] >= limit
            @log << "#{corporation.name} has reached the limit of #{limit} Influence for "\
                    "#{faction_display_name(faction_sym)} (discarded)"
            return
          end

          @corporation_influence[corporation.id][faction_sym] += 1
          faction_influence_gain(faction_sym)
          move_government(faction_sym) if moves_government
        end

        def support_factions!(corporation, factions)
          @corporations_floated_count += 1
          if @corporations_floated_count == self.class::SECOND_SUPPORT_SET_FLOAT
            @faction_support_pool = @faction_support_reserve.dup
          end

          @log << "#{corporation.name} now supports #{factions.map { |f| faction_display_name(f) }.join(' and ')}"
        end

        def corporation_factions(corporation)
          @corporation_factions[corporation.id] || []
        end

        def corporation_influence(corporation)
          @corporation_influence[corporation.id] || {}
        end

        def corporation_influence_for(corporation, faction_sym)
          corporation_influence(corporation).fetch(faction_sym, 0)
        end

        def add_corporation_influence!(corporation, faction_sym)
          @corporation_influence[corporation.id] ||= {}
          @corporation_influence[corporation.id][faction_sym] = corporation_influence_for(corporation, faction_sym) + 1
        end

        def corporation_influence_limit
          self.class::CORPORATION_INFLUENCE_LIMITS[@phase.name]
        end

        def new_auction_round
          Engine::Round::Auction.new(self, [
            GFrost1831::Step::BuyCert,
          ])
        end

        def after_buy_company(player, company, _price)
          abilities(company, :shares) do |ability|
            ability.shares.reject(&:president).each do |share|
              share_pool.buy_shares(player, share, exchange: :free)
            end
          end
          return unless company.sym == self.class::CONVOY

          @player_influence[player.id] += 1
          @log << "#{player.name} receives 1 Influence from #{company.name}"
          @use_influence.owner = player
          player.companies << @use_influence unless player.companies.include?(@use_influence)
        end

        def use_influence?(company)
          company == @use_influence
        end

        def use_influence_choices(player)
          return {} unless player_influence(player).positive?

          choices = {}
          corporations.select { |c| c.owner == player && c.type != :faction }.each do |corporation|
            corporation_factions(corporation).each do |faction|
              next unless within_influence_limit?(corporation, faction)

              choices["#{corporation.id}:#{faction}"] = "#{corporation.name} → #{faction_display_name(faction)}"
            end
          end
          factions.select { |f| f.owner == player && faction_influence(f.id) < faction_influence_limit }
                  .each { |faction| choices["#{self.class::FACTION_CHOICE}:#{faction.id}"] = faction.name }
          choices
        end

        def use_player_influence!(player, choice)
          target, faction = choice.split(':')
          spend_player_influence!(player)

          if target == self.class::FACTION_CHOICE
            faction_influence_gain(faction)
            @log << "#{player.name} allocates Influence directly to #{faction_display_name(faction)}"
          else
            corporation = corporation_by_id(target)
            add_corporation_influence!(corporation, faction)
            @log << "#{player.name} allocates Influence to #{corporation.name} (#{faction_display_name(faction)})"
          end
        end

        def spend_player_influence!(player)
          @player_influence[player.id] -= 1
          return if @player_influence[player.id].positive?

          @use_influence.close!
        end

        def num_certs(entity)
          super - entity.companies.count { |c| use_influence?(c) }
        end

        def companies_sort(companies)
          super.reject { |c| use_influence?(c) }
        end

        def entity_can_use_company?(entity, company)
          return super unless use_influence?(company)

          current = @round.current_entity
          return false unless (current&.player? ? current : current&.owner) == company.owner

          !use_influence_choices(company.owner).empty?
        end

        def player_influence(player)
          @player_influence[player.id]
        end

        def player_card_rows(player)
          influence = player_influence(player)
          return unless influence.positive?

          ['Influence', influence.to_s]
        end

        def stock_round
          GFrost1831::Round::Stock.new(self, [
            Engine::Step::DiscardTrain,
            GFrost1831::Step::Intervention,
            GFrost1831::Step::ChooseFactions,
            GFrost1831::Step::ChooseInfluence,
            GFrost1831::Step::HomeToken,
            GFrost1831::Step::Exchange,
            GFrost1831::Step::SpecialChoose,
            GFrost1831::Step::BuySellParShares,
          ])
        end

        def init_stock_market
          GFrost1831::StockMarket.new(game_market, self.class::CERT_LIMIT_TYPES,
                                      multiple_buy_types: self.class::MULTIPLE_BUY_TYPES,
                                      sold_out_top_row_movement: self.class::SOLD_OUT_TOP_ROW_MOVEMENT)
        end

        def next_round!
          return super if !@round.is_a?(GFrost1831::Round::Voting) && !voting_round_next?

          @round =
            if @round.is_a?(GFrost1831::Round::Voting)
              new_operating_round
            else
              @operating_rounds = @phase.operating_rounds
              reorder_players
              new_voting_round
            end
        end

        def voting_round_next?
          @round.is_a?(Engine::Round::Stock) && parliament_open? && !founded_factions.empty?
        end

        def new_voting_round
          @log << "-- #{round_description('Voting')} --"
          setup_voting
          voting_round
        end

        def setup_voting
          @first_voting_faction = governing_faction_sym
          @proposal_index = 0
          @locked_regulations = []
          @voting_regulation = nil
        end

        def voting_round
          GFrost1831::Round::Voting.new(self, [
            GFrost1831::Step::FirstVotingFaction,
            GFrost1831::Step::SpecialChoose,
            GFrost1831::Step::Proposal,
            GFrost1831::Step::Vote,
          ])
        end

        def new_operating_round(round_num = 1)
          @first_operating_faction = governing_faction_sym
          @favors_this_or = Hash.new(0)
          super
        end

        def operating_round(round_num)
          GFrost1831::Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            GFrost1831::Step::HomeToken,
            GFrost1831::Step::PreTurmoilInfluence,
            GFrost1831::Step::TurmoilStationLoss,
            GFrost1831::Step::Intervention,
            GFrost1831::Step::FirstOperatingFaction,
            GFrost1831::Step::FactionAction,
            GFrost1831::Step::FactionDividend,
            GFrost1831::Step::ChooseInfluence,
            GFrost1831::Step::SpecialChoose,
            GFrost1831::Step::Favor,
            GFrost1831::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            GFrost1831::Step::Track,
            GFrost1831::Step::Token,
            Engine::Step::Route,
            GFrost1831::Step::Dividend,
            Engine::Step::DiscardTrain,
            GFrost1831::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        def favor?(company)
          company == @favor_company
        end

        def assign_favor!(operator)
          @favor_company.owner = operator.type == :faction ? nil : operator
        end

        def after_end_of_operating_turn(_operator)
          @favor_company.owner = nil
        end

        def favors_used(corporation)
          @favors_used[corporation.id]
        end

        def favors_this_or(corporation)
          @favors_this_or[corporation.id]
        end

        def can_request_favor?(corporation)
          return false if available_favor_factions.empty?
          return true if forced_train_purchase?(corporation)

          favors_this_or(corporation).zero? && favors_used(corporation) < self.class::MAX_FAVORS
        end

        def available_favor_factions
          factions.select { |f| f.cash >= self.class::FAVOR_AMOUNT && f.tokens_available.positive? }
        end

        def forced_train_purchase?(corporation)
          must_buy_train?(corporation) && corporation.cash < cheapest_depot_train_price
        end

        def forced_favor?(corporation)
          favors_this_or(corporation).positive? && forced_train_purchase?(corporation)
        end

        def depot_only_train_purchase?(corporation)
          must_buy_train?(corporation) && favors_this_or(corporation) >= 2
        end

        def cheapest_depot_train_price
          @depot.min_depot_train&.price || 0
        end

        def favor_market_penalty(with_influence)
          penalties = with_influence ? self.class::FAVOR_PENALTY_WITH_INFLUENCE : self.class::FAVOR_PENALTY_WITHOUT_INFLUENCE
          penalties[regulation_value('R4')]
        end

        def price_movement_chart
          [
            %w[Condition Movement],
            ['Dividends equal to or greater than the share price', '1 →'],
            ['Dividends above £0 but lower than the share price', 'No change'],
            ['Withholding dividends', '1 ←'],
            ['Each share sold by a player', '1 ↓'],
            ['Sold Out at the end of the SR', '1 ↑'],
            ['Main Supporter of the Governing Faction during Turmoil', '1 →'],
            ['Main Supporter of the Opposing Faction during Turmoil', '1 ←'],
            ['Faction Favor, sending Influence', "#{favor_market_penalty(true)} ←"],
            ['Faction Favor, without Influence', "#{favor_market_penalty(false)} ←"],
          ]
        end

        def favor_choices(corporation)
          return {} unless can_request_favor?(corporation)

          available_favor_factions.each_with_object({}) do |faction, choices|
            corporation_factions(corporation).each do |influence|
              next unless corporation_influence_for(corporation, influence).positive?

              choices["#{faction.id}:#{influence}"] =
                "Spend #{faction_display_name(influence)} Influence (←#{favor_market_penalty(true)})"
            end
            choices["#{faction.id}:#{self.class::FAVOR_WITHOUT_INFLUENCE}"] =
              "Without spending Influence (←#{favor_market_penalty(false)})"
          end
        end

        def grant_favor!(corporation, choice)
          raise GameError, "#{choice} is not an available Favor" unless favor_choices(corporation).include?(choice)

          faction_id, influence = choice.split(':')
          faction = faction_by_id(faction_id)
          with_influence = influence != self.class::FAVOR_WITHOUT_INFLUENCE

          faction.spend(self.class::FAVOR_AMOUNT, corporation)
          @log << "#{corporation.name} receives Favor (#{format_currency(self.class::FAVOR_AMOUNT)}) from #{faction.name}"
          give_favor_influence!(corporation, faction, influence) if with_influence
          move_faction_right!(faction)
          move_favor_penalty!(corporation, favor_market_penalty(with_influence))

          @favors_used[corporation.id] += 1
          @favors_this_or[corporation.id] += 1
        end

        def give_favor_influence!(corporation, faction, influence)
          @corporation_influence[corporation.id][influence] -= 1
          @log << if faction_influence_gain(faction.id)
                    "#{corporation.name} sends Influence from #{influence} to #{faction.name}"
                  else
                    "#{corporation.name} sends Influence (#{faction.name} at limit, Influence returned)"
                  end
        end

        def move_favor_penalty!(corporation, spaces)
          from = corporation.share_price
          spaces.times do
            @stock_market.move(corporation, @stock_market.left(corporation, corporation.share_price.coordinates), force: true)
          end
          log_share_price(corporation, from)
        end

        def exhausted?(corporation)
          forced_train_purchase?(corporation) && !can_request_favor?(corporation)
        end

        def exhaust!(corporation)
          raise GameError, "#{corporation.name} is not exhausted" unless exhausted?(corporation)

          start_intervention!(corporation)
        end

        def close_corporations_in_close_cell!
          return if @intervention || @turmoil_players || @turmoil_station_loss

          corporation = @corporations.find { |c| c.type != :faction && !c.closed? && c.share_price&.type == :close }
          return unless corporation

          start_intervention!(corporation)
          true
        end

        def start_intervention!(corporation)
          @log << "-- #{corporation.name} enters Intervention Zone! --"
          factions = intervening_factions(corporation)
          give_intervention_certificates!(corporation, factions)
          compensate_certificates!(corporation)
          @intervention = { corporation: corporation, factions: factions }
          @round.clear_cache!
          finish_intervention! if intervention_replacements.empty?
        end

        def intervening_factions(corporation)
          corporation_factions(corporation).map { |f| faction_by_id(opposite_faction(f)) }.select(&:floated?)
        end

        def intervention_certificates(faction)
          @intervention_certificates[faction.id]
        end

        def give_intervention_certificates!(corporation, factions)
          factions.each do |faction|
            @intervention_certificates[faction.id] += 1
            @log << "#{faction.full_name} receives 1 certificate of #{corporation.name}"
          end
        end

        def compensate_certificates!(corporation)
          president = corporation.owner
          corporation.player_share_holders.each do |player, percent|
            next if player == president || !percent.positive?

            amount = corporation.par_price.price * (percent.to_f / corporation.share_percent).floor
            from_treasury = [corporation.cash, amount].min
            corporation.spend(from_treasury, player) if from_treasury.positive?
            pay_compensation_shortfall!(president, player, amount - from_treasury) if amount > from_treasury
            @log << "#{player.name} receives #{format_currency(amount)} compensation for #{corporation.name} shares"
          end
        end

        def pay_compensation_shortfall!(president, player, amount)
          loan = amount - president.cash
          if loan.positive?
            president.take_cash_loan(loan, @bank)
            @log << "#{president.name} takes on #{format_currency(loan)} loan"
          end
          president.spend(amount, player)
        end

        def action_processed(action)
          remove_blizzard_corporations!
          repay_player_loans!
          super
        end

        def repay_player_loans!
          @players.each { |player| payoff_player_loan(player) if player.debt.positive? && player.cash.positive? }
        end

        def intervention_choices
          return {} unless @intervention

          intervention_replacements.to_h { |token, faction| ["#{token.city.hex.id}:#{faction.id}", [token, faction]] }
        end

        def replace_station!(token, faction)
          corporation = @intervention[:corporation]
          city = token.city
          token.remove!
          city.remove_reservation!(corporation)
          city.place_token(faction, faction.next_base, check_tokenable: false)
          @log << "#{faction.full_name} replaces the station of #{corporation.name} in #{city.hex.name} with a base"
          move_faction_right!(faction)
          clear_graph
          @intervention[:factions].delete(faction)
          replacements = intervention_replacements
          return finish_intervention! if replacements.empty?

          replace_station!(*replacements.first) if replacements.one?
        end

        def intervention_replacements
          stations = @intervention[:corporation].tokens.select(&:used)
          factions = @intervention[:factions]
          most = max_replacements(stations, factions)
          return [] if most.zero?

          stations.product(factions).select do |token, faction|
            base_allowed?(faction, token) &&
              max_replacements(stations - [token], factions - [faction]) == most - 1
          end
        end

        def max_replacements(stations, factions)
          return 0 if stations.empty? || factions.empty?

          faction, *others = factions
          with_faction = stations.select { |token| base_allowed?(faction, token) }
                                 .map { |token| 1 + max_replacements(stations - [token], others) }
          [max_replacements(stations, others), *with_faction].max
        end

        def base_allowed?(faction, token)
          faction.tokens_available.positive? && !faction_base_in_hex?(faction, token.city.hex)
        end

        def faction_base_in_hex?(faction, hex)
          hex.tile.cities.any? { |city| city.tokens.any? { |t| t&.corporation == faction } }
        end

        def finish_intervention!
          corporation = @intervention[:corporation]
          @intervention = nil
          give_intervention_cards!(corporation.owner)
          remove_corporation!(corporation)
        end

        def remove_corporation!(corporation)
          @corporation_influence.delete(corporation.id)
          @corporation_factions.delete(corporation.id)
          @favors_used.delete(corporation.id)
          @log << "#{corporation.name} is removed from the game"
          close_corporation(corporation, quiet: true)
          corporation_removed!
        end

        def event_blizzard!
          @log << '-- Event: Blizzard! --'
          hexes = blizzard_hexes
          stations = hexes.flat_map { |hex| blizzard_stations(hex) }
          removed = hexes.select { |hex| clear_blizzard!(hex) }
          destroyed = stations.map { |token| destroy_blizzard_station!(token) }
          @log << "Tiles removed: #{removed.map(&:name).join(', ')}" unless removed.empty?
          @log << "Stations/bases destroyed: #{destroyed.join(', ')}" unless destroyed.empty?
          clear_graph

          @blizzard_eliminations = stations.map(&:corporation).uniq.select do |corporation|
            corporation.type != :faction && corporation.tokens.none?(&:used)
          end
        end

        def blizzard_hexes
          @hexes.select { |hex| hex.tile.icons.any? { |icon| icon.name == self.class::BLIZZARD_ICON } }
        end

        def blizzard_stations(hex)
          return [] if self.class::BLIZZARD_SURVIVING_COLORS.include?(hex.tile.color)

          hex.tile.cities.flat_map(&:tokens).compact
        end

        def clear_blizzard!(hex)
          tile = hex.tile
          yellow = tile.color == :yellow
          if yellow
            collected = new_london_route_icon(hex).nil?
            hex.lay_downgrade(hex.original_tile)
            @tiles << tile
            hex.tile.icons.delete(new_london_route_icon(hex)) if collected
          end
          hex.tile.icons.reject! { |icon| icon.name == self.class::BLIZZARD_ICON }
          yellow
        end

        def destroy_blizzard_station!(token)
          corporation = token.corporation
          hex = token.city.hex
          corporation.bases_lost += 1 if corporation.type == :faction
          token.destroy!
          "#{corporation.name} (#{hex.name})"
        end

        def crowded_corps
          super.reject(&:closed?)
        end

        def remove_blizzard_corporations!
          return if @blizzard_eliminations.empty?

          corporations = @blizzard_eliminations
          @blizzard_eliminations = []
          corporations.each do |corporation|
            @log << "#{corporation.name} has no stations left after the Blizzard"
            remove_corporation!(corporation)
          end
        end

        def give_intervention_cards!(player)
          count = self.class::INTERVENTION_CARDS[@players.size]
          count.times do
            @intervention_cards_given += 1
            card = Engine::Company.new(**self.class::INTERVENTION_CARD_COMPANY,
                                       sym: "#{self.class::INTERVENTION_CARD_COMPANY[:sym]}#{@intervention_cards_given}")
            card.owner = player
            player.companies << card
            @companies << card
          end
          update_cache(:companies)
          @log << "#{player.name} receives #{count} Intervention Card(s)"
        end

        def corporation_removed!
          @corporations_removed += 1
          return if @corporations_removed < 2

          train = @depot.min_depot_train
          return unless train

          @depot.remove_train(train)
          @log << "-- #{train.name} train removed from the game (#{@corporations_removed}th+ corporation eliminated) --"
          @phase.buying_train!(nil, train, @depot)
        end

        def parliament_open?
          @parliament_open
        end

        def event_parliament_opens!
          @log << "-- Event: New London's Parliament opens! --"
          @parliament_open = true
          factions.each { |faction| faction.ipoed = true }
        end

        def setup_parliament_track
          start_price = stock_market.market[FACTION_ROW].find { |p| p&.price == FACTION_START_PRICE }
          factions.each do |faction|
            faction.par_price = start_price
            faction.share_price = start_price
            start_price.corporations << faction
          end
        end

        def faction_share_price(faction)
          faction.share_price.price
        end

        def operating_order
          faction_operating_order + super.reject { |c| c.type == :faction }
        end

        def founded_factions
          factions.select(&:floated?)
        end

        def faction_operating_order
          founded_factions_from(@first_operating_faction)
        end

        def faction_voting_order
          founded_factions_from(@first_voting_faction)
        end

        def founded_factions_from(first_faction)
          start = faction_order.index(first_faction) || 0
          faction_order.rotate(start).filter_map { |sym| founded_factions.find { |f| f.id == sym } }
        end

        def first_operating_faction_pending?
          @first_operating_faction.nil? && founded_factions.size > 1
        end

        def first_voting_faction_pending?
          @first_voting_faction.nil? && founded_factions.size > 1
        end

        def first_faction_chooser
          @players.reject(&:bankrupt).first
        end

        def place_home_token(corporation)
          return if corporation.type == :faction

          super
        end

        def tile_lays(entity)
          entity.type == :faction ? self.class::FACTION_TILE_LAYS : super
        end

        def faction_track_cost(hex, tile)
          cost = self.class::FACTION_TRACK_COSTS[tile.color]
          return cost unless tile.color == :yellow

          cost + hex.original_tile.upgrades.sum { |upgrade| self.class::FACTION_MOUNTAIN_COSTS[upgrade.cost] || 0 }
        end

        def faction_track_cost_minimum
          self.class::FACTION_TRACK_COSTS.values.min
        end

        def faction_base_cost
          self.class::FACTION_BASE_COST
        end

        def faction_excluded_hex?(hex)
          self.class::FACTION_EXCLUDED_HEXES.include?(hex.id)
        end

        def spend_faction_influence!(faction, amount)
          @faction_influence[faction.id] -= amount
        end

        def place_faction_base!(faction, hex)
          spend_faction_influence!(faction, faction_base_cost)
          @log << "#{faction.name} places a token on #{hex.name} for #{faction_base_cost} Influences"
          move_faction_right!(faction)
        end

        def move_faction_right!(faction)
          @stock_market.move_right(faction)
          @log << "#{faction.name}'s value increases to #{format_currency(faction.share_price.price)}"
        end

        def faction_revenue_parts(faction)
          {
            'phase base income' => self.class::FACTION_BASE_INCOME[@phase.name] || 0,
            'bases' => faction.tokens.select(&:used).sum { |token| phase_revenue(token.city) },
            'Intervention Certificates' =>
              intervention_certificates(faction) * self.class::FACTION_INTERVENTION_CERTIFICATE_REVENUE,
            'Influence' => faction_influence(faction.id) * self.class::FACTION_INFLUENCE_REVENUE,
          }
        end

        def phase_revenue(revenue_center)
          color = @phase.tiles.reverse.find { |tile_color| revenue_center.revenue[tile_color] }
          color ? revenue_center.revenue[color] : 0
        end

        def faction_action_costs
          yellow = self.class::FACTION_TRACK_COSTS[:yellow]
          [
            ['Lay yellow tile (plain)', yellow],
            *self.class::FACTION_MOUNTAIN_COSTS.map do |terrain, extra|
              ["Lay yellow tile (mountain #{format_currency(terrain)})", yellow + extra]
            end,
            *self.class::FACTION_TRACK_COSTS.except(:yellow).map { |color, cost| ["Upgrade to #{color}", cost] },
            ['Place a base', faction_base_cost],
          ]
        end

        def pay_faction_dividend!(faction)
          parts = faction_revenue_parts(faction)
          revenue = parts.values.sum
          faction.operating_history[[@turn, @round.round_num]] =
            OperatingInfo.new([], nil, revenue, [], dividend_kind: 'payout')
          details = parts.select { |_, amount| amount.positive? }.map { |name, amount| "#{format_currency(amount)} #{name}" }
          @log << "#{faction.name} earns #{format_currency(revenue)} (#{details.join(', ')})"

          payouts = @players.filter_map do |player|
            amount = (revenue * player.percent_of(faction).to_f / 100).floor
            next unless amount.positive?

            @bank.spend(amount, player)
            "#{format_currency(amount)} to #{player.name}"
          end
          per_share = (revenue * faction.share_percent.to_f / 100).floor
          @log << "#{faction.name} pays #{format_currency(per_share)} per certificate"\
                  "#{payouts.empty? ? '' : " (#{payouts.join(', ')})"}"
        end

        def choose_first_operating_faction!(player, faction)
          @first_operating_faction = faction.id
          @log << "#{player.name} chooses #{faction.full_name} as first faction for Operating Round"
        end

        def choose_first_voting_faction!(player, faction)
          @first_voting_faction = faction.id
          @log << "#{player.name} chooses #{faction.full_name} as priority faction for Voting Round"
        end

        def sold_shares_destination(corporation)
          corporation.type == :faction ? :corporation : super
        end

        def sold_out_increase?(corporation)
          corporation.type != :faction && super
        end

        def available_faction_cities
          FACTION_RESERVED_CITIES.select do |hex_id|
            hex_by_id(hex_id).tile.cities.first.tokens.none? { |t| t&.corporation&.type == :faction }
          end
        end

        def reserved_for_faction?(city)
          available_faction_cities.include?(city.hex.id) && city.available_slots < 2
        end

        def faction_names
          self.class::FACTION_NAMES
        end

        def faction_order
          self.class::FACTION_ORDER
        end

        def opposite_faction(faction_sym)
          self.class::OPPOSITES[faction_sym]
        end

        def phase_extra_columns
          self.class::PHASE_INFLUENCE_LIMITS.keys
        end

        def phase_extra_value(phase, column)
          self.class::PHASE_INFLUENCE_LIMITS[column][phase[:name]]
        end

        def spreadsheet_extra_columns
          [self.class::FAVORS_COLUMN, *faction_order]
        end

        def spreadsheet_extra_value(corporation, column)
          faction = corporation.type == :faction
          if column == self.class::FAVORS_COLUMN
            return "#{faction ? favors_available(corporation) : favors_used(corporation)}/#{self.class::MAX_FAVORS}"
          end
          return (corporation.id == column ? "#{faction_influence(column)}/#{faction_influence_limit}" : '') if faction

          influence = corporation_influence_for(corporation, column)
          return '' if influence.zero? && !corporation_factions(corporation).include?(column)

          "#{influence}/#{corporation_influence_limit}"
        end

        def spreadsheet_extra_sort_value(corporation, column)
          faction = corporation.type == :faction
          return faction ? favors_available(corporation) : favors_used(corporation) if column == self.class::FAVORS_COLUMN
          return [2, 0, 0] if corporation.id == column

          order = operating_order.index(corporation) || operating_order.size
          return [1, corporation_influence_for(corporation, column), -order] if corporation_factions(corporation).include?(column)

          [0, -order, 0]
        end

        def favors_available(faction)
          (faction.cash.to_f / self.class::FAVOR_AMOUNT).floor
        end

        def faction_display_name(faction_sym)
          faction_names[faction_sym] || faction_sym
        end

        def faction_influence(faction_sym)
          @faction_influence[faction_sym]
        end

        def faction_influence_limit
          self.class::FACTION_INFLUENCE_LIMITS[@phase.name]
        end

        def faction_influence_gain(faction_sym)
          limit = faction_influence_limit
          if @faction_influence[faction_sym] >= limit
            @log << "#{faction_display_name(faction_sym)} has reached the limit of #{limit} "\
                    'Influence in Parliament (discarded)'
            return false
          end

          @faction_influence[faction_sym] += 1
          true
        end

        def faction_influence_lose(faction_sym)
          return false unless @faction_influence[faction_sym].positive?

          @faction_influence[faction_sym] -= 1
          true
        end

        def government_neutral?
          row, col = @government_marker
          self.class::GOVERNMENT_NEUTRAL_LINES.include?(row) && self.class::GOVERNMENT_NEUTRAL_LINES.include?(col)
        end

        def governing_faction_sym
          return if government_neutral?

          row, col = @government_marker
          middle = self.class::GOVERNMENT_MIDDLE
          self.class::GOVERNMENT_QUADRANTS[[row < middle, col < middle]]
        end

        def move_government(faction_sym)
          row, col = @government_marker
          destination = ParliamentMovement.move(row, col, faction_sym)

          if destination.nil?
            @log << "Government marker cannot move from (#{row},#{col}) toward #{faction_display_name(faction_sym)}"
            return
          end

          if destination == @government_marker
            @log << "Government marker already at maximum for #{faction_display_name(faction_sym)}"
            return
          end

          @government_marker = destination
          @log << "Government marker moves toward #{faction_display_name(faction_sym)}"
        end

        def event_turmoil!
          @log << '-- Event: Turmoil! --'
          if @pending_influence_queue.any? { |choice| choice[:reason] == :d_train }
            @log << 'D train influence must be allocated before Turmoil consequences'
            @deferred_turmoil = true
            return
          end

          start_turmoil!
        end

        def execute_deferred_turmoil!
          return unless @deferred_turmoil

          @deferred_turmoil = false
          start_turmoil!
        end

        def start_turmoil!
          players = @players.reject { |player| use_influence_choices(player).empty? }
          return execute_turmoil_consequences! if players.empty?

          @turmoil_players = players

          @log << 'Players with Influence may allocate before consequences are calculated.'
          @round&.clear_cache!
        end

        def turmoil_player
          @turmoil_players&.first
        end

        def use_turmoil_influence!(player, choice)
          raise GameError, "#{choice} is not available" unless use_influence_choices(player).include?(choice)

          use_player_influence!(player, choice)
          finish_turmoil_influence!(player) if use_influence_choices(player).empty?
        end

        def pass_turmoil_influence!(player)
          @log << "#{player.name} passes on using Influence"
          finish_turmoil_influence!(player)
        end

        def finish_turmoil_influence!(player)
          @turmoil_players.delete(player)
          return unless @turmoil_players.empty?

          @turmoil_players = nil
          execute_turmoil_consequences!
        end

        def execute_turmoil_consequences!
          governing = governing_faction_sym
          unless governing
            @log << 'Government is neutral — no consequences'
            return
          end

          opposition = opposite_faction(governing)
          level = ParliamentMovement.polarization_level(*@government_marker)
          @log << "Government: #{faction_display_name(governing)} (Level #{level})"
          @log << "Opposition: #{faction_display_name(opposition)}"

          government_supporter = main_supporter(governing)
          opposition_supporter = main_supporter(opposition)
          @turmoil = true
          apply_government_consequences!(faction_by_id(governing), government_supporter, level)
          apply_opposition_consequences!(faction_by_id(opposition), opposition_supporter, faction_by_id(governing), level)
          @turmoil = false
        end

        def turmoil?
          @turmoil
        end

        def main_supporter(faction_sym)
          supporters = operating_order.select do |corporation|
            corporation.type != :faction && !corporation.closed? && corporation_factions(corporation).include?(faction_sym)
          end
          supporters.max_by { |c| [corporation_influence_for(c, faction_sym), -supporters.index(c)] }
        end

        def apply_government_consequences!(faction, supporter, level)
          if supporter
            from = supporter.share_price
            @log << "#{supporter.name} (Government supporter) gains market value"
            @stock_market.move_right(supporter)
            log_share_price(supporter, from)
          end
          return if level < self.class::TURMOIL_INFLUENCE_LEVEL

          @log << if faction_influence_gain(faction.id)
                    "#{faction.full_name} gains 1 Influence in Parliament"
                  else
                    "#{faction.full_name} at Parliament limit — Influence not gained"
                  end
          gain_turmoil_corporation_influence!(supporter, faction) if supporter
          grant_turmoil_favor!(supporter, faction) if supporter && level >= self.class::TURMOIL_FAVOR_LEVEL
        end

        def apply_opposition_consequences!(faction, supporter, governing, level)
          if supporter
            from = supporter.share_price
            @log << "#{supporter.name} (Opposition supporter) loses market value"
            @stock_market.move_left(supporter)
            log_share_price(supporter, from)
          end
          return if level < self.class::TURMOIL_INFLUENCE_LEVEL

          @log << if faction_influence_lose(faction.id)
                    "#{faction.full_name} loses 1 Influence in Parliament"
                  else
                    "#{faction.full_name} has no Influence in Parliament — no loss"
                  end
          lose_turmoil_corporation_influence!(supporter, faction) if supporter
          start_turmoil_station_loss!(supporter, governing) if supporter && level >= self.class::TURMOIL_FAVOR_LEVEL
        end

        def gain_turmoil_corporation_influence!(corporation, faction)
          unless within_influence_limit?(corporation, faction.id)
            @log << "#{corporation.name} has reached the limit of #{corporation_influence_limit} Influence for "\
                    "#{faction.full_name} (discarded)"
            return
          end

          add_corporation_influence!(corporation, faction.id)
          @log << "#{corporation.name} gains 1 Influence (#{faction.full_name})"
        end

        def lose_turmoil_corporation_influence!(corporation, faction)
          unless corporation_influence_for(corporation, faction.id).positive?
            @log << "#{corporation.name} has no Influence for #{faction.full_name} — no loss"
            return
          end

          @corporation_influence[corporation.id][faction.id] -= 1
          @log << "#{corporation.name} loses 1 Influence (#{faction.full_name})"
        end

        def grant_turmoil_favor!(corporation, faction)
          if faction.cash < self.class::FAVOR_AMOUNT
            @log << "#{faction.full_name} cannot grant a Favor to #{corporation.name} (insufficient Treasury)"
            return
          end

          faction.spend(self.class::FAVOR_AMOUNT, corporation)
          @log << "#{corporation.name} receives Favor (#{format_currency(self.class::FAVOR_AMOUNT)}) from "\
                  "#{faction.name} (no market penalty)"
          move_faction_right!(faction) if faction.tokens_available.positive?
          @favors_used[corporation.id] += 1
        end

        def start_turmoil_station_loss!(corporation, faction)
          return unless turmoil_station_loss_possible?(corporation, faction)

          stations = turmoil_stations(corporation, faction)

          @turmoil_station_loss = { corporation: corporation, faction: faction }
          replace_turmoil_station!(stations.first) if stations.one?
          @round&.clear_cache!
        end

        def turmoil_station_loss_possible?(corporation, faction)
          count = corporation.tokens.count(&:used)
          reason = if count < 2
                     "#{corporation.name} has only #{count} station(s) — no loss"
                   elsif !faction.tokens_available.positive?
                     "#{faction.full_name} has no available markers — no station loss"
                   elsif turmoil_stations(corporation, faction).empty?
                     "#{faction.full_name} already has bases in all #{corporation.name}'s cities — no loss"
                   end
          @log << reason if reason
          reason.nil?
        end

        def turmoil_stations(corporation = @turmoil_station_loss[:corporation], faction = @turmoil_station_loss[:faction])
          stations = corporation.tokens.select(&:used)
          return [] if stations.size < 2 || !faction.tokens_available.positive?

          stations.reject { |token| faction_base_in_hex?(faction, token.city.hex) }
        end

        def replace_turmoil_station!(token)
          corporation = @turmoil_station_loss[:corporation]
          faction = @turmoil_station_loss[:faction]
          city = token.city
          @turmoil_station_loss = nil
          token.destroy!
          city.place_token(faction, faction.next_base, check_tokenable: false)
          @log << "#{faction.name} replaces #{corporation.name}'s station on #{city.hex.name} (Turmoil)"
          move_faction_right!(faction)
          clear_graph
        end

        def regulation_value(regulation_id)
          @regulations[regulation_id][:position]
        end

        def regulation_setting(regulation_id)
          self.class::REGULATION_SETTINGS[regulation_value(regulation_id)]
        end

        def regulation_label(regulation_id)
          "#{regulation_id} (#{@regulations[regulation_id][:name]})"
        end

        def voter_label(faction)
          "#{faction.owner&.name} (#{faction.name})"
        end

        def regulation_title(regulation_id)
          "#{regulation_id}. #{@regulations[regulation_id][:name]}"
        end

        def regulation_moves(regulation_id)
          value = regulation_value(regulation_id)
          [value - 1, value + 1].select { |v| v.between?(self.class::LOOSE, self.class::TIGHT) }
                                .map { |v| self.class::REGULATION_SETTINGS[v] }
        end

        def available_regulations
          @regulations.keys - @locked_regulations
        end

        def locked_regulation?(regulation_id)
          @locked_regulations.include?(regulation_id)
        end

        def proposer
          faction_voting_order[@proposal_index]
        end

        def proposal_pending?
          !first_voting_faction_pending? && @voting_regulation.nil? && @proposal_index < faction_voting_order.size
        end

        def voter
          voters[@voting_turn % voters.size]
        end

        def voters
          faction_voting_order.rotate(@proposal_index)
        end

        def free_vote?
          @voting_turn.zero?
        end

        def can_vote?(faction)
          faction_influence(faction.id).positive? ||
            use_influence_choices(faction.owner).include?("#{self.class::FACTION_CHOICE}:#{faction.id}")
        end

        def propose_regulation!(faction, regulation_id)
          raise GameError, "#{regulation_id} is not available" unless available_regulations.include?(regulation_id)

          @voting_regulation = regulation_id
          @voting_turn = 0
          @voting_passes = 0
          @log << "#{voter_label(faction)} chooses #{regulation_title(regulation_id)}"
        end

        def pass_proposal!(faction)
          @log << "#{voter_label(faction)} passes on proposing"
          next_proposal!
        end

        def vote_regulation!(faction, setting)
          label = regulation_label(@voting_regulation)
          raise GameError, "#{label} cannot move to #{setting}" unless regulation_moves(@voting_regulation).include?(setting)

          vote = "#{voter_label(faction)} votes #{regulation_title(@voting_regulation)}: "\
                 "#{regulation_setting(@voting_regulation)} -> #{setting}"
          if free_vote?
            @log << vote
          else
            raise GameError, "#{faction.name} has no Influence" unless faction_influence(faction.id).positive?

            spend_faction_influence!(faction, 1)
            @log << "#{vote} (spends 1 Influence)"
          end
          direction = self.class::REGULATION_SETTINGS.index(setting) > regulation_value(@voting_regulation) ? :up : :down
          move_regulation(@voting_regulation, direction)
          @voting_passes = 0
          @voting_turn += 1
        end

        def pass_vote!(faction)
          @log << "#{voter_label(faction)} #{can_vote?(faction) ? 'maintains' : 'auto-maintains (no influence)'}"
          @voting_passes += 1
          @voting_turn += 1
          lock_regulation! if @voting_passes == voters.size
        end

        def lock_regulation!
          @locked_regulations << @voting_regulation
          @log << "#{regulation_label(@voting_regulation)} is locked at #{regulation_setting(@voting_regulation)}"
          next_proposal!
        end

        def next_proposal!
          @voting_regulation = nil
          @proposal_index += 1
        end

        def move_regulation(regulation_id, direction)
          regulation = @regulations[regulation_id]
          position = regulation[:position] + (direction == :up ? 1 : -1)
          regulation[:position] = [[position, self.class::LOOSE].max, self.class::TIGHT].min
          apply_r3_limits if regulation_id == 'R3'
        end

        def r3_ownership_limit
          self.class::R3_OWNERSHIP_LIMITS[regulation_value('R3')]
        end

        def apply_r3_limits
          @corporations.each { |corporation| update_ownership_limit_for(corporation) }
        end

        def update_ownership_limit_for(corporation)
          return if corporation.type == :faction

          corporation.max_ownership_percent =
            if corporation.share_price&.type == :no_cert_limit
              self.class::NO_CERT_LIMIT_OWNERSHIP
            else
              r3_ownership_limit
            end
        end

        def upgrade_cost(tile, hex, entity, spender)
          cost = super
          return cost if tile.color == :white

          cost + r2_track_upgrade_cost(tile)
        end

        def tile_cost_with_discount(tile, hex, entity, spender, cost)
          discounted = super
          return discounted unless tile.color == :yellow

          discounted + r1_track_laying_cost
        end

        def r1_track_laying_cost
          case regulation_value('R1')
          when self.class::LOOSE then 0
          when self.class::NORMAL then @round.num_laid_track.positive? ? self.class::REGULATION_COST : 0
          else self.class::REGULATION_COST
          end
        end

        def r2_track_upgrade_cost(tile)
          case regulation_value('R2')
          when self.class::LOOSE then 0
          when self.class::NORMAL then tile.cities.empty? && tile.towns.empty? ? self.class::REGULATION_COST : 0
          else self.class::REGULATION_COST
          end
        end
      end
    end
  end
end
