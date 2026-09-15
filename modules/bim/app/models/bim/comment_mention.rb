# frozen_string_literal: true

module Bim
  class CommentMention < ApplicationRecord
    self.table_name = 'bim_comment_mentions'

    belongs_to :comment, class_name: 'Bim::Bcf::Comment'
    belongs_to :user

    validates :comment_id, uniqueness: { scope: :user_id }
    validates :user, presence: true
    validates :comment, presence: true

    # Scopes
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :for_comment, ->(comment_id) { where(comment_id: comment_id) }
    scope :recent, -> { order(created_at: :desc) }

    # Find all comments where a user was mentioned
    def self.mentioned_comments_for_user(user)
      Comment.joins(:mentions).where(bim_comment_mentions: { user_id: user.id })
    end

    # Find all users mentioned in a comment
    def self.mentioned_users_in_comment(comment)
      User.joins(:comment_mentions).where(bim_comment_mentions: { comment_id: comment.id })
    end
  end
end
