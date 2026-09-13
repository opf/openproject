#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim::Bcf
  class Comment < ApplicationRecord
    self.table_name = :bcf_comments

    include InitializeWithUuid

    CREATE_ATTRIBUTES = %i[journal issue viewpoint reply_to status].freeze
    UPDATE_ATTRIBUTES = %i[viewpoint reply_to status].freeze

    belongs_to :journal
    belongs_to :issue, class_name: "Bim::Bcf::Issue"
    belongs_to :viewpoint, class_name: "Bim::Bcf::Viewpoint", optional: true
    belongs_to :reply_to, foreign_key: :reply_to, class_name: "Bim::Bcf::Comment", optional: true

    # Collaboration enhancement: mentions
    has_many :mentions, class_name: 'Bim::CommentMention', foreign_key: :comment_id, dependent: :destroy
    has_many :mentioned_users, through: :mentions, source: :user

    # Collaboration enhancement: replies
    has_many :replies, class_name: "Bim::Bcf::Comment", foreign_key: :reply_to, dependent: :nullify

    validates_presence_of :uuid
    validates_uniqueness_of :uuid, scope: [:issue_id]
    validates :status, inclusion: { in: %w[question issue suggestion resolved info], allow_nil: true }

    # Callbacks
    after_create :parse_mentions!
    after_create :notify_mentioned_users

    def self.has_uuid?(uuid, issue_id)
      exists?(uuid:, issue_id:)
    end

    # Collaboration enhancement: Mention parsing
    # Extracts @username mentions from journal notes and creates mention records
    def parse_mentions!
      return unless journal&.notes.present?

      text = journal.notes
      usernames = text.scan(/@(\w+)/).flatten.uniq

      usernames.each do |username|
        user = User.find_by(login: username)
        mentions.find_or_create_by!(user: user) if user
      end
    end

    # Collaboration enhancement: Reactions
    # reactions JSONB format: { "👍": [user_id1, user_id2], "✅": [user_id3] }

    # Add a reaction from a user
    def add_reaction(emoji, user_id)
      current_reactions = reactions || {}
      current_reactions[emoji] ||= []
      current_reactions[emoji] << user_id unless current_reactions[emoji].include?(user_id)
      update(reactions: current_reactions)
    end

    # Remove a reaction from a user
    def remove_reaction(emoji, user_id)
      current_reactions = reactions || {}
      return unless current_reactions[emoji]

      current_reactions[emoji].delete(user_id)
      current_reactions.delete(emoji) if current_reactions[emoji].empty?
      update(reactions: current_reactions)
    end

    # Toggle a reaction (add if not present, remove if present)
    def toggle_reaction(emoji, user_id)
      current_reactions = reactions || {}
      if current_reactions.dig(emoji)&.include?(user_id)
        remove_reaction(emoji, user_id)
      else
        add_reaction(emoji, user_id)
      end
    end

    # Get count for a specific reaction
    def reaction_count(emoji)
      reactions&.dig(emoji)&.size || 0
    end

    # Check if user has reacted with specific emoji
    def user_reacted?(emoji, user_id)
      reactions&.dig(emoji)&.include?(user_id) || false
    end

    # Get all reactions with user details
    def reactions_summary
      return [] unless reactions

      reactions.map do |emoji, user_ids|
        {
          emoji: emoji,
          count: user_ids.size,
          users: User.where(id: user_ids).pluck(:id, :firstname, :lastname, :login).map do |id, first, last, login|
            { id: id, name: "#{first} #{last}", login: login }
          end
        }
      end
    end

    # Status helpers
    def question?
      status == 'question'
    end

    def issue?
      status == 'issue'
    end

    def suggestion?
      status == 'suggestion'
    end

    def resolved?
      status == 'resolved'
    end

    def info?
      status == 'info'
    end

    private

    def notify_mentioned_users
      mentioned_users.each do |user|
        # Use OpenProject's notification system
        # This will be handled by the NotificationService
        Bim::Collaboration::NotificationService.notify_mention(
          user: user,
          comment: self
        )
      end
    rescue StandardError => e
      Rails.logger.error "Failed to notify mentioned users: #{e.message}"
    end
  end
end
