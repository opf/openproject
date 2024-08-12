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

class Message < ApplicationRecord
  include OpenProject::Journal::AttachmentHelper

  belongs_to :forum
  has_one :project, through: :forum
  belongs_to :author, class_name: "User"
  acts_as_tree counter_cache: :replies_count, order: "#{Message.table_name}.created_at ASC"
  acts_as_attachable after_add: :attachments_changed,
                     after_remove: :attachments_changed,
                     add_on_new_permission: :add_messages,
                     add_on_persisted_permission: :edit_messages
  belongs_to :last_reply, class_name: "Message"

  acts_as_journalized

  acts_as_event title: Proc.new { |o| "#{o.forum.name}: #{o.subject}" },
                description: :content,
                type: Proc.new { |o| o.parent_id.nil? ? "message" : "reply" },
                url: (Proc.new do |o|
                        msg = o
                        if msg.parent_id.nil?
                          { id: msg.id }
                        else
                          { id: msg.parent_id, r: msg.id, anchor: "message-#{msg.id}" }
                        end.reverse_merge controller: "/messages", action: "show", forum_id: msg.forum_id
                      end)

  acts_as_searchable columns: ["subject", "content"],
                     include: { forum: :project },
                     references: [:forums],
                     project_key: "project_id",
                     date_column: "#{table_name}.created_at"

  acts_as_watchable

  validates :forum, :subject, :content, presence: true
  validates :subject, length: { maximum: 255 }

  before_save :set_sticked_on_date
  after_create :add_author_as_watcher,
               :update_last_reply_in_parent
  after_update :update_ancestors, if: :saved_change_to_forum_id?
  after_destroy :reset_counters

  scope :visible, ->(*args) {
    includes(forum: :project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_messages))
  }

  def visible?(user = User.current)
    !user.nil? && user.allowed_in_project?(:view_messages, project)
  end

  validate :validate_unlocked_root, on: :create

  # Can not reply to a locked topic
  def validate_unlocked_root
    errors.add :base, "Topic is locked" if root.locked? && self != root
  end

  def set_sticked_on_date
    self.sticked_on = if sticky?
                        sticked_on.nil? ? Time.now : sticked_on
                      end
  end

  # TODO: move into create contract
  def update_last_reply_in_parent
    if parent
      parent.reload
      parent.update_attribute(:last_reply_id, id)
    end

    forum.reset_counters!
  end

  def reset_counters
    forum.reset_counters!
  end

  def sticky=(arg)
    write_attribute :sticky, (arg == true || arg.to_s == "1" ? 1 : 0)
  end

  def sticky?
    sticky == 1
  end

  def editable_by?(usr)
    usr && usr.logged? &&
    (usr.allowed_in_project?(:edit_messages, project) || (author == usr && usr.allowed_in_project?(:edit_own_messages, project)))
  end

  def destroyable_by?(usr)
    usr && usr.logged? &&
    (usr.allowed_in_project?(:delete_messages,
                             project) || (author == usr && usr.allowed_in_project?(:delete_own_messages, project)))
  end

  private

  def update_ancestors
    with_id = Message.where(id: root.id)
    with_parent_id = Message.where(parent_id: root.id)

    with_id
      .or(with_parent_id)
      .update_all(forum_id:)

    Forum.reset_counters!(forum_id_before_last_save)
    Forum.reset_counters!(forum_id)
  end

  def add_author_as_watcher
    Watcher.create(watchable: root, user: author)
    # update watchers and watcher_users
    watchers.reload
    watcher_users.reload
  end
end
