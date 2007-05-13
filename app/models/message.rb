# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class Message < ActiveRecord::Base
  belongs_to :board
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  acts_as_tree :counter_cache => :replies_count, :order => "#{Message.table_name}.created_on ASC"
  has_many :attachments, :as => :container, :dependent => :destroy
  belongs_to :last_reply, :class_name => 'Message', :foreign_key => 'last_reply_id'
  
  validates_presence_of :subject, :content
  validates_length_of :subject, :maximum => 255
  
  def after_create
    board.update_attribute(:last_message_id, self.id)
    board.increment! :messages_count
    if parent
      parent.reload.update_attribute(:last_reply_id, self.id)
    else
      board.increment! :topics_count
    end
  end
end
