# frozen_string_literal: true

module API
  module V3
    module Bim
      class CommentReactionsController < ApplicationController
        before_action :find_comment
        before_action :authorize

        # GET /api/v3/bim/comments/:comment_id/reactions
        def index
          service = ::Bim::Collaboration::ReactionService.new(@comment)

          render json: {
            _type: 'CommentReactions',
            comment_id: @comment.id,
            reactions: service.reactions_summary,
            allowed_reactions: ::Bim::Collaboration::ReactionService::ALLOWED_REACTIONS
          }
        end

        # POST /api/v3/bim/comments/:comment_id/reactions
        def create
          service = ::Bim::Collaboration::ReactionService.new(@comment)
          result = service.add_reaction(
            emoji: params[:emoji],
            user: current_user
          )

          if result.success?
            render json: {
              _type: 'CommentReactions',
              message: 'Reaction added',
              reactions: result.result
            }, status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/comments/:comment_id/reactions/toggle
        def toggle
          service = ::Bim::Collaboration::ReactionService.new(@comment)
          result = service.toggle_reaction(
            emoji: params[:emoji],
            user: current_user
          )

          if result.success?
            render json: {
              _type: 'CommentReactions',
              message: 'Reaction toggled',
              reactions: result.result
            }
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/comments/:comment_id/reactions
        def destroy
          service = ::Bim::Collaboration::ReactionService.new(@comment)
          result = service.remove_reaction(
            emoji: params[:emoji],
            user: current_user
          )

          if result.success?
            render json: {
              _type: 'CommentReactions',
              message: 'Reaction removed',
              reactions: result.result
            }
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        private

        def find_comment
          @comment = ::Bim::Bcf::Comment.find(params[:comment_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Comment not found' }, status: :not_found
        end

        def authorize
          # Check if user has permission to view BCF comments
          unless current_user.allowed_in_project?(:view_linked_issues, @comment.issue.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
      end
    end
  end
end
