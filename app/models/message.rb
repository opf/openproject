#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Message < ActiveRecord::Base
  include Redmine::SafeAttributes
  include OpenProject::Journal::AttachmentHelper

  belongs_to :board
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  acts_as_tree counter_cache: :replies_count, order: "#{Message.table_name}.created_on ASC"
  acts_as_attachable after_add: :attachments_changed,
                     after_remove: :attachments_changed
  belongs_to :last_reply, class_name: 'Message', foreign_key: 'last_reply_id'

  acts_as_journalized

  acts_as_event title: Proc.new { |o| "#{o.board.name}: #{o.subject}" },
                description: :content,
                datetime: :created_on,
                type: Proc.new { |o| o.parent_id.nil? ? 'message' : 'reply' },
                url: (Proc.new do |o|
                        msg = o
                        if msg.parent_id.nil?
                          { id: msg.id }
                        else
                          { id: msg.parent_id, r: msg.id, anchor: "message-#{msg.id}" }
                        end.reverse_merge controller: '/messages', action: 'show', board_id: msg.board_id
                      end)

  acts_as_searchable columns: ['subject', 'content'],
                     include: { board: :project },
                     project_key: 'project_id',
                     date_column: "#{table_name}.created_on"

  acts_as_watchable

  attr_protected :author_id

  validates_presence_of :board, :subject, :content
  validates_length_of :subject, maximum: 255

  after_create :add_author_as_watcher
  after_create :update_last_reply_in_parent
  after_update :update_ancestors
  after_destroy :reset_counters

  scope :visible, lambda {|*args|
    { include: { board: :project },
      conditions: Project.allowed_to_condition(args.first || User.current, :view_messages) }
  }

  safe_attributes 'subject', 'content', 'board_id'
  safe_attributes 'locked', 'sticky',
                  if: lambda {|message, user|
                    user.allowed_to?(:edit_messages, message.project)
                  }

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_messages, project)
  end

  validate :validate_unlocked_root, on: :create

  before_save :set_sticked_on_date

  # Can not reply to a locked topic
  def validate_unlocked_root
    errors.add :base, 'Topic is locked' if root.locked? && self != root
  end

  def set_sticked_on_date
    if sticky?
      self.sticked_on = sticked_on.nil? ? Time.now : sticked_on
    else
      self.sticked_on = nil
    end
  end

  def update_last_reply_in_parent
    if parent
      parent.reload.update_attribute(:last_reply_id, id)
    end
    board.reset_counters!
  end

  def update_ancestors
    if board_id_changed?
      Message.update_all("board_id = #{board_id}", ['id = ? OR parent_id = ?', root.id, root.id])
      Board.reset_counters!(board_id_was)
      Board.reset_counters!(board_id)
    end
  end

  def reset_counters
    board.reset_counters!
  end

  def sticky=(arg)
    write_attribute :sticky, (arg == true || arg.to_s == '1' ? 1 : 0)
  end

  def sticky?
    sticky == 1
  end

  def project
    board.project
  end

  def editable_by?(usr)
    usr && usr.logged? && (usr.allowed_to?(:edit_messages, project) || (author == usr && usr.allowed_to?(:edit_own_messages, project)))
  end

  def destroyable_by?(usr)
    usr && usr.logged? && (usr.allowed_to?(:delete_messages, project) || (author == usr && usr.allowed_to?(:delete_own_messages, project)))
  end

  private

  def add_author_as_watcher
    Watcher.create(watchable: root, user: author)
    # update watchers and watcher_users
    watchers(true)
    watcher_users(true)
  end
end
