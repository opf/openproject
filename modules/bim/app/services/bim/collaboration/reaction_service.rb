# frozen_string_literal: true

module Bim
  module Collaboration
    class ReactionService
      ALLOWED_REACTIONS = %w[👍 👎 ✅ ❓ ❤️ 🎉 🚀 👀].freeze

      def initialize(comment)
        @comment = comment
      end

      # Add a reaction
      def add_reaction(emoji:, user:)
        unless valid_reaction?(emoji)
          return ServiceResult.failure(errors: "Invalid reaction emoji: #{emoji}")
        end

        @comment.add_reaction(emoji, user.id)
        broadcast_reaction_update

        ServiceResult.success(result: @comment.reactions_summary)
      end

      # Remove a reaction
      def remove_reaction(emoji:, user:)
        @comment.remove_reaction(emoji, user.id)
        broadcast_reaction_update

        ServiceResult.success(result: @comment.reactions_summary)
      end

      # Toggle a reaction
      def toggle_reaction(emoji:, user:)
        unless valid_reaction?(emoji)
          return ServiceResult.failure(errors: "Invalid reaction emoji: #{emoji}")
        end

        @comment.toggle_reaction(emoji, user.id)
        broadcast_reaction_update

        ServiceResult.success(result: @comment.reactions_summary)
      end

      # Get all reactions for the comment
      def reactions_summary
        @comment.reactions_summary
      end

      # Get reactions grouped by emoji
      def grouped_reactions
        @comment.reactions_summary.group_by { |r| r[:emoji] }
      end

      private

      def valid_reaction?(emoji)
        ALLOWED_REACTIONS.include?(emoji)
      end

      def broadcast_reaction_update
        return unless defined?(Turbo)

        # Broadcast updated reactions to all users viewing this comment
        Turbo::StreamsChannel.broadcast_replace_to(
          "comment_#{@comment.id}_reactions",
          target: "comment_#{@comment.id}_reactions",
          html: render_reactions_html
        )
      end

      def render_reactions_html
        # This would render a partial with current reactions
        # For now, return empty string
        ''
      end
    end
  end
end
