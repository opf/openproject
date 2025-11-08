# frozen_string_literal: true

module API
  module V3
    module Bim
      class CommentMentionsController < ApplicationController
        before_action :authorize

        # GET /api/v3/bim/comment_mentions
        # Get all mentions for the current user
        def index
          mentions = ::Bim::CommentMention.for_user(current_user.id)
                                          .includes(comment: [:issue, :journal])
                                          .recent

          # Optionally filter by read/unread status
          if params[:unread] == 'true'
            # Filter to mentions for comments created after user's last view
            # This would require additional tracking - simplified for now
          end

          render json: {
            _type: 'Collection',
            total: mentions.count,
            count: mentions.size,
            _embedded: {
              elements: mentions.map { |m| mention_representer(m) }
            }
          }
        end

        # GET /api/v3/bim/comments/:comment_id/mentions
        # Get all mentions in a specific comment
        def show
          comment = ::Bim::Bcf::Comment.find(params[:comment_id])
          authorize_comment_access(comment)

          mentions = comment.mentions.includes(:user)

          render json: {
            _type: 'CommentMentions',
            comment_id: comment.id,
            total: mentions.count,
            mentioned_users: mentions.map { |m| user_representer(m.user) }
          }
        end

        private

        def authorize
          # Basic authorization - user must be logged in
          head :unauthorized unless current_user
        end

        def authorize_comment_access(comment)
          unless current_user.allowed_in_project?(:view_linked_issues, comment.issue.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def mention_representer(mention)
          comment = mention.comment

          {
            _type: 'CommentMention',
            id: mention.id,
            created_at: mention.created_at.iso8601,
            comment: {
              id: comment.id,
              uuid: comment.uuid,
              text: comment.journal.notes,
              created_at: comment.journal.created_at.iso8601,
              author: user_representer(comment.journal.user)
            },
            issue: {
              id: comment.issue.id,
              uuid: comment.issue.uuid,
              title: comment.issue.work_package.subject
            },
            _links: {
              self: { href: api_v3_paths.bim_comment(comment.id) },
              issue: { href: api_v3_paths.work_package(comment.issue.work_package_id) }
            }
          }
        end

        def user_representer(user)
          {
            id: user.id,
            name: user.name,
            login: user.login,
            avatar_url: user.avatar_url
          }
        end
      end
    end
  end
end
