#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Forum < ApplicationRecord
  belongs_to :project
  has_many :topics, -> {
    where("#{Message.table_name}.parent_id IS NULL")
      .order("#{Message.table_name}.sticky DESC")
  }, class_name: 'Message'
  has_many :messages, -> {
    order("#{Message.table_name}.sticky DESC")
  }, dependent: :destroy
  belongs_to :last_message, class_name: 'Message'
  acts_as_list scope: :project_id
  acts_as_watchable permission: :view_messages

  validates :name, :description, presence: true
  validates :name, length: { maximum: 256 }
  validates :description, length: { maximum: 255 }

  def visible?(user = User.current)
    !user.nil? && user.allowed_in_project?(:view_messages, project)
  end

  def to_s
    name
  end

  def reset_counters!
    self.class.reset_counters!(id)
  end

  # Updates topics_count, messages_count and last_message_id attributes for +forum_id+
  def self.reset_counters!(forum_id)
    forum_id = forum_id.to_i
    where(id: forum_id)
      .update_all("topics_count = (SELECT COUNT(*) FROM #{Message.table_name} WHERE forum_id=#{forum_id} AND parent_id IS NULL)," +
               " messages_count = (SELECT COUNT(*) FROM #{Message.table_name} WHERE forum_id=#{forum_id})," +
               " last_message_id = (SELECT MAX(id) FROM #{Message.table_name} WHERE forum_id=#{forum_id})")
  end
end
