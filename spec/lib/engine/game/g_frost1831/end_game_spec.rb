# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module GFrost1831
      describe Game do
        let(:game) { Engine::Game::GFrost1831::Game.new(%w[P1 P2 P3], id: 1) }
        let(:p1) { game.players[0] }
        let(:p2) { game.players[1] }
        let(:cm) { game.corporation_by_id('CM') }
        let(:tec) { game.corporation_by_id('TEC') }

        def messages
          game.log.map(&:message)
        end

        def end_game
          game.bank.spend(game.bank.cash, p2)
          game.end_game!(:bank)
        end

        before do
          game.event_parliament_opens!
          [tec.presidents_share, tec.ipo_shares.reject(&:president).first].each { |share| share.transfer(p2) }
          tec.owner = p2
          game.par_corporation(cm, game.stock_market.par_prices.first)
          cm.ipoed = true
          cm.floated = true
          cm.presidents_share.transfer(p1)
          cm.owner = p1
          game.instance_variable_get(:@corporation_factions)[cm.id] = %w[TEC LOR]
          game.instance_variable_get(:@corporation_influence)[cm.id] = { 'TEC' => 3, 'LOR' => 1 }
          game.instance_variable_get(:@faction_influence)['TEC'] = 5
          game.instance_variable_set(:@government_marker, Game::GOVERNMENT_START.dup)
        end

        it 'moves the Corporation Influence to the Factions and converts every 4 Influence into a token' do
          price = tec.share_price.price
          end_game

          expect(game.finished).to be(true)
          expect(messages).to include('-- Event: Endgame Turmoil! --', 'Government is neutral — no consequences',
                                      'CM moves 3 Influence to Technicians', 'CM moves 1 Influence to Lords',
                                      "Technicians has 8 Influence and converts into 2 tokens. TEC's value increases to "\
                                      "#{game.format_currency(tec.share_price.price)}")
          expect(game.faction_influence('TEC')).to eq(8)
          expect(game.corporation_influence(cm)).to eq({})
          expect(tec.share_price.price).to be > price
          expect(messages.last).to start_with('-- Game over')
        end

        it 'limits the conversion to the tokens left in Parliament' do
          game.instance_variable_get(:@faction_influence)['TEC'] = 40
          available = tec.tokens_available
          end_game

          expect(messages).to include(a_string_matching(/^Technicians has \d+ Influence and converts into #{available} tokens\./))
          expect(tec.tokens_available).to eq(0)
        end

        it 'lets players use their Influence before the Endgame Turmoil' do
          game.instance_variable_get(:@player_influence)[p1.id] = 1
          end_game

          expect(game.finished).to be(false)
          expect(game.round).to be_a(GFrost1831::Round::FinalResolution)
          expect(game.round.active_step).to be_a(GFrost1831::Step::PreTurmoilInfluence)

          game.process_action(Engine::Action::Pass.new(p1))

          expect(game.exception&.message).to be_nil
          expect(game.finished).to be(true)
          expect(messages).to include('P1 passes on using Influence',
                                      a_string_starting_with('Technicians has 8 Influence and converts into 2 tokens.'))
        end
      end
    end
  end
end
