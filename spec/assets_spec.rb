# frozen_string_literal: true

require 'spec_helper'
require 'assets'

TEST_CASES = [
  ['1889',
   314,
   [[6, 'stock_round', 'Pass (Share)'],
    [13, 'float', 'KO receives ¥700'],
    [21, 'lay_track', ['1889: Phase 2 - Operating Round 1.1 (of 1) - Lay/Upgrade Track', '!!min-content']],
    [23, 'buy_train',
     ['KO must buy an available train',
      '!!Player 1 must contribute']],
    [48, 'run_routes', '1889: Phase 2 - Operating Round 2.1 (of 1) - Run Routes'],
    [49, 'dividends', '1889: Phase 2 - Operating Round 2.1 (of 1) - Pay or Withhold Dividends'],
    [80,
     'buy_company',
     ['1889: Phase 3 - Operating Round 3.1 (of 1) - Buy Companies',
      'Owning corporation may ignore building cost for mountain hexes']],
    [83,
     'track_and_buy_company',
     ['1889: Phase 3 - Operating Round 3.1 (of 1) - Lay/Upgrade Track',
      'Show companies from other players']],
    [89,
     'special_track',
     ['1889: Phase 3 - Operating Round 3.1 (of 1) - Lay Track for Ehime Railway',
      'Blocks C4 while owned by a player.']],
    [338, 'discard_train', 'Discard Trains'],
    [349, 'buy_train_emr', 'TR must buy an available train'],
    [448,
     'buy_train_emr_shares',
     ['KO has ¥582',
      'Player 1 must contribute ¥518 for KO to afford a train from the Depot',
      'Player 1 has ¥74 in cash',
      'Player 1 has ¥650 in sellable shares',
      'Player 1 must sell shares to raise at least ¥444',
      '!!Bankruptcy']],
    [nil, 'endgame', '1889: Phase D - Operating Round 7.1 (of 3) - Game Over - Bankruptcy']]],
  ['1882',
   5236,
   [[399, 'sc_home_token', '1882: Phase 4 - Stock Round 6 - Place Home Token'],
    [229, 'qll_home_token', '1882: Phase 3 - Operating Round 4.1 (of 1) - Place Home Token'],
    [370, 'nwr_place_token', '1882: Phase 4 - Operating Round 5.2 (of 2) - NWR: Place Token'],
    [371, 'nwr_lay_track', '1882: Phase 4 - Operating Round 5.2 (of 2) - NWR: Lay Track']]],
  ['1846',
   3099,
   [[0, 'draft', '1846: Phase I - Draft Round 1 - Draft Companies'],
    [18, 'draft', 'Mail Contract'],
    [49,
     'lay_track_or_token',
     ['1846: Phase I - Operating Round 1.1 (of 2) - Place a Token or Lay Track',
      # Minor charter stuff
      'Michigan Southern', 'Trains', '2', 'Cash', 'C15', '$60']],
    [74,
     'issue_shares',
     ['1846: Phase I - Operating Round 1.1 (of 2) - Place a Token or Lay Track',
      'Issue', '1 ($50)', '2 ($100)', '3 ($150)', '4 ($200)']],
    [94,
     'dividend',
     ['Pay or Withhold Dividends',
      '2 right',
      '1 right',
      '1 left']],
    [142,
     'assign',
     ['1846: Phase II - Operating Round 2.1 (of 2) - Assign Steamboat Company',
      'Player 4 may assign Steamboat Company to a new hex and/or corporation or minor.',
      'Add a bonus to the value of one port city']],
    [nil, 'endgame', '1846: Phase IV - Operating Round 6.2 (of 2) - Game Over - Bank Broken']]],
  ['1846', 'hs_cvjhogoy_1599504419', [[49, 'buy_train_emr_shares', 'has $60 in sellable shares']]],
  ['1846', 'hs_sudambau_1600037415', [[37, 'buy_train', ['GT has $280', '!!can issue shares']]]],
  ['1846',
   'hs_sudambau_1600037415',
   [[60,
     'buy_train_bankrupt',
     ['B&amp;O has $0',
      'Player 3 must contribute $160 for B&amp;O to afford a train from the Depot.',
      'Player 3 has $15',
      'Player 3 has $0 in sellable shares',
      'Player 3 does not have enough liquidity to contribute towards B&amp;O buying a '\
      'train from the Depot. B&amp;O must buy a train from another corporation, or Player 3 '\
      'must declare bankruptcy.',
      'Declare Bankruptcy']]]],
  ['18AL',
   4714,
   [[nil, 'endgame', '18AL: Phase 5 - Operating Round 7.2 (of 3) - Game Over - Company hit max stock value']]],
  ['18TN',
   7818,
   [[nil, 'endgame', '18TN: Phase 8 - Operating Round 8.2 (of 3) - Game Over - Bank Broken']]],
  ['18MS',
   14_375,
   [[nil, 'endgame', '18MS: Phase D - Operating Round 10 (of 10) - Game end after OR 10 - Game Over']]],
  ['18MEX',
   13_315,
   [[265,
     'merge',
     ['Merge',
      'Decline',
      'Corporations that can merge with NdM']]]],
  ['18MEX',
   17_849,
   [[nil, 'endgame', '18MEX: Phase 4D - Operating Round 4.2 (of 2) - Game Over - Bankruptcy']]],
  ['1817',
   20_758,
   [[369,
     'choose_corp_size',
     ['1817: Phase 3 - Stock Round 2 - Buy or Sell Shares',
      'Strasburg Railroad',
      'Loans', '0/2',
      'Number of Shares:', '2', '5']]]],
  ['1817',
   15_528,
   [[196,
     'merge',
     ['Convert',
      'Merge',
      'Grand Trunk Western Railroad',
      'Corporations that can merge with A&amp;S']],
    [205, 'offer', ['Offer for Sale', 'Warren &amp; Trumbull Railroad']],
    [383,
     'merge_with_other_players',
     ['Convert',
      'Merge',
      'Pittsburgh, Shawmut and Northern Railroad',
      'Corporations that can merge with J']],
    [1502,
     'stock',
     ['Stock Round 7',
      'Final phase was reached',
      'buys a 10% share of Bess from the market for $165']]]],
  ['1817',
   16_852,
   [[889, 'cash_crisis', ['Player 2 owes the bank $294 and must raise cash if possible.']]]],
  ['1817',
   16_281,
   [[809,
     'buy_sell_post_conversion',
     ['Merger Round 4.2 (of 2) - Buy/Sell Shares Post Conversion',
      'New York, Susquehanna and Western Railway']]]],
  ['1817NA',
   25_351,
   [[nil, 'endgame', '1817NA: Phase 7 - Acquisition Round 5.1 (of 2) - Game Over - Bankruptcy']]],
  ['18Chesapeake',
   1905,
   [[153, 'blocking_special_track', ['Lay Track for Columbia - Philadelphia Railroad']]]],
  ['18Chesapeake',
   22_383,
   [[56, 'removing_share_from_market',
     ['Stock Round 3 - Sell then Buy Shares',
      'Player 2 removes a 10% share of SRR from the game',
      'Player 2 buys a 10% share of SRR from the market for $95']]]],
  ['18CO',
   22_032,
   [[309,
     'corporate_share_buy',
     ['Pass (Share Buy)',
      'Buy Market Share',
      'Buy DPAC Share',
      'Buy CM Share']],
    [315,
     'corporate_share_sale',
     ['Pass (Share Sale)',
      'Kansas Pacific Railway',
      'Sell 1 ($40)',
      'Sell 2 ($80)',
      'Sell 3 ($120)']],
    [nil, 'pass', ['18CO: Phase 7 - Operating Round 6.2 (of 2) - Game Over - Bank Broken']]]],
  ['1867',
   21_268,
   [[531,
     'mid_convert',
     ['Choose Major Corporation']],
    [533,
     'buy_shares_post_merge',
     ['Buy Shares Post Merge',
      'Buy Treasury Share']],
    [698,
     'major_nationalize',
     ['Nationalize Major',
      'Choose if Major is nationalized',
      'Grand Trunk Railway']],
    [nil,
     'endgame',
     ['Operating Round 6.3 (of 3) - Game Over']]]],
  ['1860',
   19_354,
   [[215,
     'stock_round_1',
     ['!!<div>Fishbourne Ferry Company',
      '<div>Cowes Marina and Harbour',
      '<div>Brading Harbour Company']],
    [350,
     'stock_round_2',
     ['<div>Fishbourne Ferry Company',
      '<div>Cowes Marina and Harbour',
      '<div>Brading Harbour Company']],
    [444,
     'stock_round_3',
     ['<div>Fishbourne Ferry Company',
      '!!<div>Cowes Marina and Harbour',
      '!!<div>Brading Harbour Company']],
    [nil,
     'endgame',
     ['1860: Phase 9 - Operating Round 8.4 (Nationalization) - Game Over - Nationalization complete']]]],

  ['1822CA',
   2,
   [[nil,
     'endgame',
     ['GWR (P10) places a token on N16 (Winnipeg)',
      'P10 (Winnipeg Station) closes',
      '1822CA: Phase 7 - Operating Round 8.1 (of 2) - Game Over']]]],
  ['1868 Wyoming',
   144_719,
   [[433,
     'double headed trains',
     ['Operating Round 3.2 (of 2)',
      '3+2 [5+4]']]]],
  ['1841',
   132_002,
   [[939,
     'endgame',
     ['1841: Phase 8 - Operating Round 7.1 (of 3) - Game Over - Company hit max stock value']]]],
  ['18NY',
   108_746,
   [[130,
     'stock',
     ['Stock Round 3',
      '10 receives $110 in its Treasury']]]],
].freeze

AUTO_ACTIONS_TEST_CASES = [
  ['1889',
   314,
   [[7, 'buy_to_float', [
    'Auto Buy Shares',
    'KO',
   ]]],
   ['1817',
    15_528,
    [[141, 'merger', [
      'Auto Pass in Mergers',
      'A&S',
      'Merger and Conversion Round',
    ]]]]],
].freeze

describe 'Assets' do
  before(:all) { @subject = Assets.new }

  subject { @subject }

  def render(**needs)
    subject.html('assets/app/app.rb', **needs)
  end

  describe '#html' do
    it 'renders logged out' do
      expect(render).to include('18xx.Games')
    end

    it 'renders home logged in' do
      expect(render(user: { name: 'toby', settings: { consent: true } })).to include('Profile (toby)')
    end

    it 'consent logged in' do
      expect(render(user: { name: 'toby' })).to include('I agree to the privacy policy')
    end

    it 'renders about' do
      expect(render(app_route: '/about')).to include('created and maintained')
    end

    it 'renders tiles' do
      expect(render(app_route: '/tiles/all')).to include('Generic Map Hexes')

      expect(render(app_route: '/tiles/57')).to include('57')

      expect(render(app_route: '/tiles/18Chesapeake/all')).to include('I9')

      expect(render(app_route: '/tiles/18Chesapeake/I9')).to include('I9')
      expect(render(app_route: '/tiles/18Chesapeake/X1')).to include('X1')
      x2_x3 = render(app_route: '/tiles/18Chesapeake/X2+X3')
      expect(x2_x3).to include('X2')
      expect(x2_x3).to include('X3')

      aggregate_failures 'location name for all stop types' do
        with_loc_names = render(app_route: '/tiles/18Chesapeake/B2+H6+K3')
        %w[B2 Pittsburgh H6 Baltimore K3 Trenton Amboy D&amp;R].each do |str|
          expect(with_loc_names).to include(str)
        end
      end

      multiple_games = render(app_route: '/tiles/1889+18Chesapeake/all')
      expect(multiple_games).to include('Kouchi')
      expect(multiple_games).to include('Delmarva')

      %w[1889 18Chesapeake].each do |title|
        rendered = render(app_route: "/tiles/#{title}/all")

        expect(rendered).to include("#{title} Map Hexes")
        expect(rendered).to include("#{title} Tile Manifest")
        expect(rendered).not_to include('TODO')
      end
    end

    it 'renders login' do
      expect(render(app_route: '/login')).to include('Login')
    end

    it 'renders signup' do
      expect(render(app_route: '/signup')).to include('Signup')
    end

    context '/map' do
      {
        # games with config but not full implementation; just do a quick spot check
        '1817' => %w[Pittsburgh],
        '1817NA' => %w[
          Anchorage The Klondike Dawson City Hazelton Arctic Edmonton Winnipeg
          Quebec Europe Seattle Denver Toronto New York Hawaii Los Angeles
          Guadalajara Mexico City Miami New Orleans Belize South America
          20 30 40 50 60 80 15 10 B Asia
        ],
        '1846' => %w[Chicago],

        # games with full implementation; verify every string on the map
        '1889' => %w[
          1 10 11 12 13 14 2 20 3 30 4 40 5 6 60 7 8 80 9 A AR Anan Awaji B C D
          D100 D80 E ER F G H I IR Ikeda Imabari J K KO Komatsujima Kotohira
          Kouchi Kouen KU Kubokawa L Marugame Matsuyama Muki Muroto Nahari
          Nakamura Nangoku Naruto Niihama Ohzu Okayama Ritsurin SR Saijou
          Sakaide Sukumo T TR Takamatsu Tokushima UR Uwajima Yawatahama
        ],
        '18Chesapeake' => %w[
          1 10 100 11 12 13 14 2 3 30 4 40 5 50 6 60 7 8 80 9 A Allentown Amboy
          B B&amp;O B&amp;S Baltimore Berlin Burlington C C&amp;A C&amp;O
          C&amp;OC C-P Camden Charleroi Charlottesville Coal Columbia
          Connellsville D D&amp;R DC Delmarva E Easton F Fredericksburg G Green
          H Hagerstown Harrisburg I J K L LV Leesburg Lynchburg N&amp;W New
          Norfolk OO Ohio PLE PRR Peninsula Philadelphia Pittsburgh Princeton
          Richmond SRR Spring Strasburg Trenton Virginia Washington West
          Wilmington York
        ],
      }.each do |game_title, expected_strings|
        context game_title do
          it 'renders map' do
            rendered = render(app_route: "/map/#{game_title}")

            aggregate_failures 'expected strings' do
              expected_strings.each { |s| expect(rendered).to include(s) }
            end
          end
        end
      end
    end

    it 'renders new_game' do
      expect(render(app_route: '/new_game')).to include('Create New Game')
      expect(render(app_route: '/new_game', title: '1889')).to include('Shikoku 1889')
    end

    it 'renders game' do
      needs = {
        game_data: {
          id: 1,
          user: { id: 1, name: 'Player 1' },
          players: [{ id: 1, name: 'Player 1' }, { id: 2, name: 'Player 2' }],
          title: '1889',
          actions: [],
          loaded: true,
        },
        user: {
          id: 1,
          name: 'Player 1',
          settings: { consent: true },
        },
      }

      expect(render(app_route: '/game/1', **needs)).to include('Takamatsu E-Railroad')
      expect(render(app_route: '/game/1#entities', **needs)).to include('entities', 'Player 1', 'Awa Railroad')
      expect(render(app_route: '/game/1#map', **needs)).to include('Kotohira')
      expect(render(app_route: '/game/1#market', **needs)).to include('The Bank', 'Cash', 'Par value')
      expect(render(app_route: '/game/1#info', **needs)).to include('Trains', 'Game Phases', 'Shikoku 1889',
                                                                    'Trains in Bank Pool')
      expect(render(app_route: '/game/1#tiles', **needs)).to include('492')
      expect(render(app_route: '/game/1#spreadsheet', **needs)).to include('Value')
      expect(render(app_route: '/game/1#tools', **needs)).to include('Clone Game')
      expect(render(app_route: '/game/1#auto', **needs)).to include('Auto Actions')
      expect(render(app_route: '/game/1', **needs)).not_to include('arliament')
    end

    it 'renders Minor E track controls with only the blue-terrain point remaining' do
      script = <<~RUBY
        require_tree 'engine/game/g_18_oe'
        game = Engine::Game::G18OE::Game.new({ 1 => 'Player 1', 2 => 'Player 2', 3 => 'Player 3' }, id: 1, seed: 1)
        entity = game.corporation_by_id('E')
        entity.owner = game.players.first
        game.bank.spend(120, entity)
        game.minor_floated_regions['E'] = 'UK'
        city = game.hex_by_id('J27').tile.cities.first
        city.remove_all_reservations!
        city.place_token(entity, entity.tokens.first, free: true)
        round = Engine::Round::Operating.new(game, [Engine::Game::G18OE::Step::Track], round_num: 1)
        round.entities = [entity]
        round.instance_variable_set(:@current_operator, entity)
        game.instance_variable_set(:@round, round)
        step = round.steps.last
        step.instance_variable_set(:@points_used, 3)
        hex = game.hex_by_id('J29')
        hex.lay(Engine::Tile.from_code('J29', :white, 'double_town=revenue:0;upgrade=cost:45,terrain:river'))
        game.graph.clear
        raise 'Eligible zero-point hex should keep Track active' unless step.auto_actions(entity).nil?
        tile = step.upgradeable_tiles(entity, hex).first
        selector = Lib::TileSelector.new(hex, tile, [0, 0], nil, entity, :map)
        user = { 'id' => 1, 'name' => 'Player 1', 'settings' => { 'consent' => true } }
        data = { 'id' => 1, 'title' => '18OE', 'actions' => [], 'loaded' => true,
                 'status' => 'active', 'user' => user, 'players' => game.players.map { |p| { 'id' => p.id, 'name' => p.name } } }
        html = View::GamePage.html(game: game, game_data: data, user: user, app_route: '/game/1', tile_selector: selector)
        hex.lay(Engine::Tile.from_code('J29', :white, 'double_town=revenue:0'))
        game.graph.clear
        auto_actions = step.auto_actions(entity)
        unless auto_actions&.map { |action| [action.type, action.entity] } == [['pass', entity]]
          raise 'Expected one automatic Pass for E when no zero-point candidate remains'
        end
        html
      RUBY
      html = subject.context(['18OE']).eval(Opal.compile(script))

      expect(html).to include('Lay Track', '0 track points + 1 blue-terrain point (yellow lays only)',
                              'Skip (Track)', '✔', '✖')
      expect(html).not_to include('cannot be continued')
    end

    it 'renders Minor F track controls and independent E/F points on an acquiring major' do
      script = <<~RUBY
        require_tree 'engine/game/g_18_oe'
        game = Engine::Game::G18OE::Game.new({ 1 => 'Player 1', 2 => 'Player 2', 3 => 'Player 3' }, id: 1, seed: 1)
        entity = game.corporation_by_id('F')
        entity.owner = game.players.first
        game.bank.spend(120, entity)
        game.minor_floated_regions['F'] = 'UK'
        city = game.hex_by_id('J27').tile.cities.first
        city.remove_all_reservations!
        city.place_token(entity, entity.tokens.first, free: true)
        round = Engine::Round::Operating.new(game, [Engine::Game::G18OE::Step::Track], round_num: 1)
        round.entities = [entity]
        round.instance_variable_set(:@current_operator, entity)
        game.instance_variable_set(:@round, round)
        step = round.steps.last
        step.instance_variable_set(:@points_used, 3)
        hex = game.hex_by_id('J29')
        hex.lay(Engine::Tile.from_code('J29', :white, 'double_town=revenue:0;upgrade=cost:45,terrain:mountain'))
        game.graph.clear
        raise 'Eligible green zero-point hex should keep Track active' unless step.auto_actions(entity).nil?
        tile = step.upgradeable_tiles(entity, hex).first
        selector = Lib::TileSelector.new(hex, tile, [0, 0], nil, entity, :map)
        user = { 'id' => 1, 'name' => 'Player 1', 'settings' => { 'consent' => true } }
        data = { 'id' => 1, 'title' => '18OE', 'actions' => [], 'loaded' => true,
                 'status' => 'active', 'user' => user, 'players' => game.players.map { |p| { 'id' => p.id, 'name' => p.name } } }
        minor_html = View::GamePage.html(game: game, game_data: data, user: user,
                                        app_route: '/game/1', tile_selector: selector)
        major = game.corporation_by_id('LNWR')
        major.type = :major
        major.owner = game.players.first
        game.add_minor_charter!(game.corporation_by_id('E'), major)
        game.add_minor_charter!(entity, major)
        city.remove_tokens!
        city.place_token(major, major.tokens.first, free: true)
        game.graph.clear
        round = Engine::Round::Operating.new(game, [Engine::Game::G18OE::Step::Track], round_num: 1)
        round.entities = [major]
        round.instance_variable_set(:@current_operator, major)
        game.instance_variable_set(:@round, round)
        round.steps.last.instance_variable_set(:@points_used, 6)
        major_html = View::GamePage.html(game: game, game_data: data, user: user, app_route: '/game/1')
        [minor_html, major_html]
      RUBY
      minor_html, major_html = subject.context(['18OE']).eval(Opal.compile(script))

      expect(minor_html).to include('Lay Track', '0 track points + 1 green-terrain point (yellow lays only)',
                                    'Skip (Track)', '✔', '✖')
      expect(major_html).to include('0 track points + 1 blue-terrain point + 1 green-terrain point (yellow lays only)',
                                    'Skip (Track)')
      expect(minor_html + major_html).not_to include('cannot be continued')
    end

    describe 'Frost 1831' do
      def frost_game_until_float
        game = Engine::Game::GFrost1831::Game.new({ 1 => 'Player 1', 2 => 'Player 2', 3 => 'Player 3' }, id: 1)
        100.times do
          break unless game.round.is_a?(Engine::Round::Auction)

          entity = game.current_entity
          step = game.round.active_step
          auctioning = step.auctioning
          company = step.available.find(&:company?)
          game.process_action(
            if auctioning.is_a?(Engine::Corporation)
              Engine::Action::Par.new(entity, corporation: auctioning,
                                              share_price: step.get_par_prices(entity, auctioning).first)
            elsif !auctioning && company
              Engine::Action::Bid.new(entity, company: company, price: company.value)
            else
              Engine::Action::Pass.new(entity)
            end
          )
        end
        corporation = game.corporation_by_id('CM')
        player = game.current_entity
        game.process_action(Engine::Action::Par.new(player, corporation: corporation,
                                                            share_price: game.stock_market.par_prices.first))
        20.times do
          break if corporation.floated?

          entity = game.current_entity
          game.process_action(
            if entity == player
              Engine::Action::BuyShares.new(entity, shares: corporation.ipo_shares.first, percent: 10)
            else
              Engine::Action::Pass.new(entity)
            end
          )
        end
        game
      end

      it 'renders the Influence Arena below the Faction choice' do
        game = frost_game_until_float
        expect(game.round.active_step).to be_a(Engine::Game::GFrost1831::Step::ChooseFactions)

        player = game.current_entity
        needs = {
          game_data: {
            id: 1,
            user: { id: player.id, name: player.name },
            players: game.players.map { |p| { id: p.id, name: p.name } },
            title: 'Frost 1831',
            actions: game.actions.map(&:to_h),
            loaded: true,
          },
          user: { id: player.id, name: player.name, settings: { consent: true } },
        }

        expect(render(app_route: '/game/1', **needs)).to include('Choose faction to support for', 'Influence Arena')
      end

      it 'renders the Influence Arena below the Influence choice' do
        game = frost_game_until_float
        corporation = game.corporation_by_id('CM')
        2.times do
          game.process_action(Engine::Action::Choose.new(game.current_entity, choice: game.round.active_step.choices.keys.first))
        end
        50.times do
          break if game.round.active_step.is_a?(Engine::Game::GFrost1831::Step::ChooseInfluence)

          entity = game.current_entity
          step = game.round.active_step
          share = corporation.ipo_shares.first
          game.process_action(
            if share && step.actions(entity).include?('buy_shares') && step.can_buy?(entity, share.to_bundle)
              Engine::Action::BuyShares.new(entity, shares: share, percent: share.percent)
            else
              Engine::Action::Pass.new(entity)
            end
          )
        end
        expect(game.round.active_step).to be_a(Engine::Game::GFrost1831::Step::ChooseInfluence)

        player = corporation.owner
        needs = {
          game_data: {
            id: 1,
            user: { id: player.id, name: player.name },
            players: game.players.map { |p| { id: p.id, name: p.name } },
            title: 'Frost 1831',
            actions: game.actions.map(&:to_h),
            loaded: true,
          },
          user: { id: player.id, name: player.name, settings: { consent: true } },
        }

        expect(render(app_route: '/game/1', **needs)).to include('Allocate Influence for CM (Influence Zone)', 'Influence Arena')
      end

      def frost_bot_action(game, step, entity, actions, neutral: false)
        if actions.include?('choose')
          choice = (frost_neutral_choice(game, step) if neutral) || step.choices.keys.first
          choice = 'pass' if step.is_a?(Engine::Game::GFrost1831::Step::Vote) && step.choices.include?('pass')
          choice = game.intervention_choices.keys.first if step.is_a?(Engine::Game::GFrost1831::Step::Intervention)
          Engine::Action::Choose.new(entity, choice: choice)
        elsif actions.include?('place_token') && !step.is_a?(Engine::Game::GFrost1831::Step::FactionAction)
          hex = game.hexes.find { |h| step.available_hex(entity, h) }
          Engine::Action::PlaceToken.new(entity, city: hex.tile.cities.first, slot: 0)
        elsif actions.include?('buy_shares')
          (frost_neutral_buy(game, step, entity) if neutral) || frost_bot_buy(game, step, entity)
        elsif actions.include?('run_routes')
          Engine::Action::RunRoutes.new(entity, routes: [])
        elsif actions.include?('dividend')
          Engine::Action::Dividend.new(entity, kind: 'withhold')
        elsif actions.include?('buy_train') && frost_bot_train(game, step, entity)
          train = game.depot.min_depot_train
          Engine::Action::BuyTrain.new(entity, train: train, price: train.price)
        else
          Engine::Action::Pass.new(entity)
        end
      end

      def frost_neutral_distances
        movements = Engine::Game::GFrost1831::ParliamentMovement::MOVEMENTS
        distances = { '3,4' => 0 }
        until distances.size == movements.size
          movements.each do |from, destinations|
            reachable = destinations.filter_map { |d| distances[d] }.min
            distances[from] = reachable + 1 if reachable && !distances[from]
          end
        end
        distances
      end

      def frost_neutral_choice(game, step)
        row, col = game.government_marker
        step.choices.keys.min_by do |sym|
          destination = Engine::Game::GFrost1831::ParliamentMovement.move(row, col, sym)
          destination ? frost_neutral_distances[destination.join(',')] : 99
        end
      end

      def frost_neutral_buy(game, step, player)
        return Engine::Action::Pass.new(player) if game.government_neutral? && game.founded_factions.size > 1

        row, col = game.government_marker
        faction = game.factions.select { |f| step.can_buy?(player, f.ipo_shares.first&.to_bundle) }.min_by do |f|
          frost_neutral_distances[Engine::Game::GFrost1831::ParliamentMovement.move(row, col, f.id)&.join(',')] || 99
        end
        Engine::Action::BuyShares.new(player, shares: faction.ipo_shares.first, percent: 10) if faction
      end

      def frost_bot_buy(game, step, player)
        cm = game.corporation_by_id('CM')
        intervening = game.corporation_factions(cm).map { |f| game.corporation_by_id(game.opposite_faction(f)) }
        faction = intervening.find do |f|
          !f.floated? && game.players.none? { |p| p != player && p.percent_of(f).positive? } &&
            step.can_buy?(player, f.ipo_shares.first.to_bundle)
        end
        return Engine::Action::BuyShares.new(player, shares: faction.ipo_shares.first, percent: 10) if faction

        corporations = game.corporations.reject { |c| c.type == :faction }
        unless corporations.any? { |c| c.owner == player }
          corporation = corporations.find { |c| game.can_par?(c, player) }
          price = game.stock_market.par_prices.find { |p| p.price == 100 }
          return Engine::Action::Par.new(player, corporation: corporation, share_price: price)
        end

        corporation = corporations.find { |c| c.owner == player && !c.floated? }
        share = corporation&.ipo_shares&.first
        return Engine::Action::Pass.new(player) if !share || !step.can_buy?(player, share.to_bundle)

        Engine::Action::BuyShares.new(player, shares: share, percent: 10)
      end

      def frost_bot_train(game, step, corporation)
        train = game.depot.min_depot_train
        wanted = train.name == '2' || (train.name == '3' && !game.parliament_open?)
        wanted &&= corporation.id != 'CM' || corporation.trains.empty?
        wanted && corporation.cash >= train.price && step.room?(corporation)
      end

      def frost_play_until(game, step_class, neutral: false)
        400.times do
          step = game.round.active_step
          break if step.instance_of?(step_class)

          entity = game.current_entity
          game.process_action(frost_bot_action(game, step, entity, step.actions(entity), neutral: neutral))
        end
        expect(game.round.active_step).to be_an_instance_of(step_class)
      end

      it 'shows the Faction choices as logos and widens the Operating Round column for the Influence Arena' do
        data = JSON.parse(File.read('spec/fixtures/frost_1831/hs_fqaxxsno_1794865941.json'))

        render_game_at_action(data.dup, 22, ['title="Technicians (2)" width="48"', 'title="Expansionists (2)" width="48"'])
        render_game_at_action(data.dup, 43, ['title="Technicians" width="48"', 'min-width: min-content',
                                             '!!>Technicians</button>'])
        render_game_at_action(data.dup, 250, ['CM → Guardians</button>', 'min-width: min-content'])
      end

      it 'shows the Favors and Influence columns in the spreadsheet' do
        data = JSON.parse(File.read('spec/fixtures/frost_1831/hs_fqaxxsno_1794865941.json'))
        render_game_at_action(data, 300, %w[Favors 4/5 5/8], '#spreadsheet')
      end

      def render_frost(game, tab = '', optional_rules: [])
        player = game.active_players.first
        player = player.owner unless player.player?
        render(
          app_route: "/game/1#{tab}",
          game_data: {
            id: 1,
            user: { id: player.id, name: player.name },
            players: game.players.sort_by(&:id).map { |p| { id: p.id, name: p.name } },
            title: 'Frost 1831',
            settings: { optional_rules: optional_rules },
            actions: game.actions.map(&:to_h),
            loaded: true,
          },
          user: { id: player.id, name: player.name, settings: { consent: true } },
        )
      end

      it 'renders the map to choose the stations of an Intervention' do
        game = frost_game_until_float
        frost_play_until(game, Engine::Game::GFrost1831::Step::Intervention)

        expect(render_frost(game)).to include('New Grand Junction is being intervened.',
                                              'Choose which faction between Guardians and Expansionists receives the station.',
                                              'map-hexes')
      end

      it 'renders the choice of the first Faction to operate' do
        game = frost_game_until_float
        frost_play_until(game, Engine::Game::GFrost1831::Step::FirstOperatingFaction, neutral: true)

        expect(render_frost(game)).to include('Which Faction operates first?', 'Technicians', 'Lords')
      end

      it 'renders the Influence Arena when players use Influence before the Turmoil' do
        game = frost_game_until_float
        400.times do
          step = game.round.active_step
          break if step.is_a?(Engine::Game::GFrost1831::Step::PreTurmoilInfluence)

          entity = game.current_entity
          actions = step.actions(entity)
          train = game.depot.min_depot_train
          game.process_action(
            if actions.include?('buy_train') && entity.cash >= train.price && step.room?(entity)
              Engine::Action::BuyTrain.new(entity, train: train, price: train.price)
            else
              frost_bot_action(game, step, entity, actions)
            end
          )
        end
        expect(game.round.active_step).to be_a(Engine::Game::GFrost1831::Step::PreTurmoilInfluence)

        expect(render_frost(game)).to include('Use Influence before Turmoil?', 'Influence Arena', '→')
      end

      it 'renders the turn of a Faction' do
        game = frost_game_until_float
        frost_play_until(game, Engine::Game::GFrost1831::Step::FactionAction)

        expect(render_frost(game)).to include('Lay Track or Place a Base', 'Skip (Track/Base)', 'Influence Cost',
                                              'Lay yellow tile (plain)', 'Place a base')
      end

      it 'renders the price movement chart and the phase statuses' do
        game = frost_game_until_float

        expect(render_frost(game, '#market')).to include('Main Supporter of the Governing Faction during Turmoil',
                                                         'Faction Favor, sending Influence')
        info = render_frost(game, '#info')
        expect(info).to include('Parliament Opens', 'Turmoil', 'Blizzard', '◆ Corp Limit', '◆ Faction Limit')
        expect(info).not_to include('Trains in Bank Pool')
        expect(render_frost(game, '#spreadsheet')).not_to include('No Trains in Bank Pool')
      end

      it 'renders the Parliament tab' do
        game = frost_game_until_float

        expect(render_frost(game)).to include('#parliament')
        expect(render_frost(game, '#parliament')).to include('New London', 'Influence Arena',
                                                             'Market Regulation', 'Turmoils', 'OPPOSITION')
      end

      it 'renders the Supporter Bypass in the train-buying step' do
        game = frost_game_until_float
        400.times do
          step = game.round.active_step
          entity = game.current_entity
          break if step.is_a?(Engine::Game::GFrost1831::Step::BuyTrain) && step.actions(entity).include?('choose')

          game.process_action(frost_bot_action(game, step, entity, step.actions(entity)))
        end

        expect(render_frost(game)).to include('Upgrade Trains', 'Influence by', '◆')
      end

      it 'renders the optional rules in the Info tab' do
        game = Engine::Game::GFrost1831::Game.new({ 1 => 'Player 1', 2 => 'Player 2', 3 => 'Player 3' },
                                                  id: 1, optional_rules: [:tight_regulation])

        expect(render_frost(game, '#info', optional_rules: [:tight_regulation]))
          .to include('Tight Regulation', 'All 4 Market Regulation criteria begin at Tight Regulation')
      end

      it 'renders the Proposal of a Voting Round with the Market Regulation' do
        game = frost_game_until_float
        frost_play_until(game, Engine::Game::GFrost1831::Step::Proposal)

        expect(render_frost(game)).to include('Criterion', 'R1. Track Laying', 'R4. Favor', 'Market Regulation',
                                              'R1. Track Laying', '£0 + £20', 'hammer.svg')
      end

      it 'renders the vote on the proposed criterion' do
        game = frost_game_until_float
        frost_play_until(game, Engine::Game::GFrost1831::Step::Vote)

        expect(render_frost(game)).to include('R1. Track Laying Vote', 'Loosen (0◆)', 'Tighten (0◆)', 'Market Regulation',
                                              'Shareholder')
      end

      it 'renders the Favor ability of the operating Corporation' do
        game = frost_game_until_float
        favor = game.companies.find { |c| game.favor?(c) }
        400.times do
          break if game.round.is_a?(Engine::Round::Operating) && !game.round.actions_for(favor).empty?

          step = game.round.active_step
          entity = game.current_entity
          game.process_action(frost_bot_action(game, step, entity, step.actions(entity)))
        end
        expect(game.round.actions_for(favor)).to eq(%w[choose_ability])

        expect(render_frost(game)).to include("Favor (#{favor.owner.name})")
      end
    end

    def render_game_at_action(data, action_count, string, suffix = '')
      data['actions'] = data['actions'].take(action_count) if action_count
      data[:loaded] = true
      needs = {
        game_data: data,
        user: data['user'].merge(settings: { consent: true }),
      }

      html = render(app_route: "/game/#{needs[:game_data]['id']}#{suffix}", **needs)
      strings = Array(string)
      strings.each do |str|
        if /^!!/.match?(str)
          expect(html).not_to include(str.slice(2..))
        else
          expect(html).to include(str)
        end
      end
    end

    def render_game(jsonfile, action_count, string)
      data = JSON.parse(File.read(jsonfile))
      render_game_at_action(data, action_count, string)
    end

    TEST_CASES.each do |game, game_id, actions|
      dir = Engine.meta_by_title(game).fixture_dir_name
      data = JSON.parse(File.read("spec/fixtures/#{dir}/#{game_id}.json"))
      actions.each do |action_config|
        action, step, string = action_config
        describe "#{game} #{game_id}" do
          it "renders #{step} #{action}" do
            render_game_at_action(data.dup, action, string)
          end
        end
      end
    end

    AUTO_ACTIONS_TEST_CASES.each do |game, game_id, actions|
      data = JSON.parse(File.read("spec/fixtures/#{game}/#{game_id}.json"))
      actions.each do |action_config|
        action, step, string = action_config
        describe "#{game} #{game_id}" do
          it "renders auto #{step} #{action}" do
            render_game_at_action(data.dup, action, string, '#auto')
          end
        end
      end
    end

    it 'renders tutorial to the end' do
      render_game('public/assets/tutorial.json', nil, 'Good luck and have fun!')
    end
  end
end
