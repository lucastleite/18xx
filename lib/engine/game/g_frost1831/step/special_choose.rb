# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module GFrost1831
      module Step
        class SpecialChoose < Engine::Step::SpecialChoose
          def choices_ability(entity)
            if entity.sym == 'FAV'
              return favor_choices(entity)
            end

            return [] unless entity.owner&.player?

            case entity.sym
            when 'INF'
              inf_choices(entity)
            when 'PAF'
              p4_choices(entity)
            else
              {}
            end
          end

          def process_choose_ability(action)
            company = action.entity

            if company.sym == 'FAV'
              return process_favor(action)
            end

            case company.sym
            when 'INF'
              process_inf(action)
            when 'PAF'
              process_p4(action)
            end
          end

          private

          # === INF (Use Influence): Allocate 1 influence cube ===

          def inf_choices(entity)
            player = entity.owner
            choices = {}

            return {} unless @game.player_influence(player).positive?

            # Option 1: allocate to a corporation the player presides
            @game.corporations.select { |c| c.owner == player && c.type != :faction && @game.corporation_factions(c).any? }.each do |corp|
              @game.corporation_factions(corp).each do |faction|
                next unless @game.within_influence_limit?(corp, faction)

                choices["#{corp.id}:#{faction}"] = "#{corp.name} → #{faction_name(faction)}"
              end
            end

            # Option 2: allocate directly to a faction the player presides
            @game.corporations.select { |c| c.owner == player && c.type == :faction }.each do |faction|
              next unless @game.faction_influence(faction.id) < @game.faction_influence_limit

              choices["faction:#{faction.id}"] = faction.name
            end

            choices
          end

          def process_inf(action)
            company = action.entity
            player = company.owner
            choice = action.choice

            raise GameError, 'No Influence to allocate' unless @game.player_influence(player).positive?

            @game.player_influence_spend(player)

            if choice.start_with?('faction:')
              faction_sym = choice.split(':').last
              faction = @game.corporations.find { |c| c.id == faction_sym }
              raise GameError, 'Not president of that faction' unless faction&.owner == player

              @game.faction_influence_gain(faction_sym)
              @log << "#{player.name} allocates influence directly to #{faction.name}"
            else
              corp_id, faction_sym = choice.split(':')
              corporation = @game.corporations.find { |c| c.id == corp_id }
              raise GameError, 'Not president of that corporation' unless corporation&.owner == player

              @game.add_corporation_influence(corporation, faction_sym)
              @log << "#{player.name} allocates influence to #{corporation.name} (#{faction_name(faction_sym)})"
            end

            # Close the INF company if no more cubes (player used all influence)
            unless @game.player_influence(player).positive?
              company.close!
              @log << 'Use Influence ability consumed'
            end
          end

          # === P4 (Affiliate): Exchange for 1 faction share ===

          def p4_choices(entity)
            player = entity.owner
            choices = {}

            @game.corporations.select { |c| c.type == :faction }.each do |faction|
              next unless @game.parliament_open?
              next unless faction.ipo_shares.any?(&:buyable)
              # Respect opposition rule
              next if opposing_faction?(player, faction)
              # Respect 60% limit
              next if player.percent_of(faction) >= 60

              choices[faction.id] = "#{faction.name} (#{@game.format_currency(@game.faction_share_price(faction))})"
            end

            choices
          end

          def process_p4(action)
            company = action.entity
            player = company.owner
            choice = action.choice

            faction = @game.corporations.find { |c| c.id == choice }
            raise GameError, 'Invalid faction' unless faction
            raise GameError, 'Parliament not open' unless @game.parliament_open?
            raise GameError, 'No shares available' unless faction.ipo_shares.any?(&:buyable)
            raise GameError, 'Opposition rule' if opposing_faction?(player, faction)
            raise GameError, 'Exceeds 60% limit' if player.percent_of(faction) >= 60

            # Transfer 1 share from IPO to player (no cost — exchanging the private)
            share = faction.ipo_shares.find(&:buyable)
            @game.share_pool.transfer_shares(share.to_bundle, player)

            # Faction gains 1 influence cube
            @game.faction_influence_gain(faction.id)

            @log << "#{player.name} exchanges #{company.name} for a share of #{faction.name}"

            # Close the private company (consumed)
            company.close!
            @log << "#{company.name} is closed"
          end

          def opposing_faction?(player, faction)
            opposites = @game.class::OPPOSITES
            opposite_sym = opposites[faction.id]
            return false unless opposite_sym

            opposite = @game.corporations.find { |c| c.id == opposite_sym }
            return false unless opposite

            player.percent_of(opposite).positive?
          end

          def faction_name(sym)
            case sym
            when 'TEC' then 'Technicians'
            when 'GUA' then 'Guardians'
            when 'EXP' then 'Expansionists'
            when 'LOR' then 'Lords'
            else sym
            end
          end

          # === Faction Favor ===

          def favor_choices(entity)
            corporation = @game.round.respond_to?(:current_operator) ? @game.round.current_operator : nil
            return {} unless corporation
            return {} unless @game.can_request_favor?(corporation)

            # If not in favor mode yet, just offer to enter
            unless @round.respond_to?(:favor_mode) && @round.favor_mode
              return { 'enter_favor' => 'Request Favor' }
            end

            # In favor mode: accept cancel and apply choices
            choices = { 'cancel' => 'Cancel Favor' }

            @game.available_favor_factions(corporation).each do |faction|
              @game.corporation_factions(corporation).each do |faction_sym|
                choices["apply:#{faction.id}:#{faction_sym}"] = "Apply"
              end
              choices["apply:#{faction.id}:none"] = "Apply"
            end

            choices
          end

          def process_favor(action)
            choice = action.choice
            corporation = @game.round.current_operator

            if choice == 'enter_favor'
              @round.favor_mode = true if @round.respond_to?(:favor_mode=)
              return
            end

            if choice == 'cancel'
              @round.favor_mode = false if @round.respond_to?(:favor_mode=)
              return
            end

            if choice.start_with?('apply:')
              parts = choice.split(':')
              faction_id = parts[1]
              influence_target = parts[2]
              faction = @game.corporations.find { |c| c.id == faction_id }
              with_influence_to = influence_target == 'none' ? nil : influence_target

              @game.execute_favor(corporation, faction, with_influence_to)

              # Check if corporation landed in intervention zone
              if corporation.share_price&.type == :close
                @round.favor_mode = false if @round.respond_to?(:favor_mode=)
                @game.remove_favor_from_operator(corporation)
                @game.trigger_intervention(corporation)
                return
              end

              # Exit favor mode normally
              @round.favor_mode = false if @round.respond_to?(:favor_mode=)
              @game.remove_favor_from_operator(corporation)
            end
          end
        end
      end
    end
  end
end
