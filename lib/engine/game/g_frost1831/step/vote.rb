# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GFrost1831
      module Step
        class Vote < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def offers
            []
          end

          def actions(entity)
            return [] if @game.voting_finished?
            return [] unless entity&.owner == @game.current_voting_president

            ACTIONS
          end

          def active_entities
            faction = @game.current_voting_faction
            faction ? [faction] : []
          end

          def active?
            !@game.voting_finished?
          end

          def blocking?
            active?
          end

          def description
            faction = @game.current_voting_faction
            case @game.voting_phase
            when :propose
              "#{faction&.name}: Choose a criterion"
            when :propose_direction
              reg = @game.current_voting_regulation
              "#{faction&.name}: Vote on #{reg&.[](:name)}"
            when :vote
              reg = @game.current_voting_regulation
              "Voting: #{reg&.[](:name)}"
            else
              'Voting'
            end
          end

          def choice_name
            case @game.voting_phase
            when :propose
              'Criterion'
            when :propose_direction
              reg = @game.current_voting_regulation
              "#{@game.current_voting_regulation_id}. #{reg&.[](:name)} Vote"
            when :vote
              reg = @game.current_voting_regulation
              "#{@game.current_voting_regulation_id}. #{reg&.[](:name)} Vote"
            else
              'Choice'
            end
          end

          def choices
            case @game.voting_phase
            when :propose
              propose_criterion_choices
            when :propose_direction
              propose_direction_choices
            when :vote
              vote_choices
            else
              {}
            end
          end

          def process_choose(action)
            choice = action.choice
            entity = action.entity
            player = entity.owner

            case @game.voting_phase
            when :propose
              process_criterion_choice(player, choice)
            when :propose_direction
              process_direction_choice(player, choice)
            when :vote
              process_vote_action(player, choice)
            end
          end

          private

          def propose_criterion_choices
            choices = {}
            @game.available_regulations.each do |reg_id, reg|
              choices[reg_id] = "#{reg_id}. #{reg[:name]}"
            end
            choices['pass'] = 'Pass'
            choices
          end

          def propose_direction_choices
            reg = @game.current_voting_regulation
            return {} unless reg

            # Proposer MUST move (cannot maintain) — this is their free vote
            choices = {}
            case reg[:position]
            when 0
              choices['up'] = 'Normalize (0◆)'
            when 1
              choices['down'] = 'Loosen (0◆)'
              choices['up'] = 'Tighten (0◆)'
            when 2
              choices['down'] = 'Normalize (0◆)'
            end
            choices
          end

          def vote_choices
            reg = @game.current_voting_regulation
            return {} unless reg

            choices = {}
            case reg[:position]
            when 0
              choices['up'] = 'Normalize (1◆)'
            when 1
              choices['down'] = 'Loosen (1◆)'
              choices['up'] = 'Tighten (1◆)'
            when 2
              choices['down'] = 'Normalize (1◆)'
            end
            choices['maintain'] = 'Maintain (0◆)'
            choices
          end

          def process_criterion_choice(player, choice)
            faction = @game.current_voting_faction

            if choice == 'pass'
              @log << "#{player.name} (#{faction.name}) passes on proposing"
              @game.proposer_passes
              return
            end

            @game.select_voting_criterion(choice)
          end

          def process_direction_choice(player, choice)
            faction = @game.current_voting_faction

            @game.propose_regulation(player, @game.current_voting_regulation_id, choice.to_sym)
          end

          def process_vote_action(player, choice)
            faction = @game.current_voting_faction

            if choice == 'maintain'
              @log << "#{player.name} (#{faction&.name}) maintains"
              @game.voting_pass(player)
              return
            end

            @game.cast_vote(player, @game.current_voting_regulation_id, choice.to_sym)
          end
        end
      end
    end
  end
end
