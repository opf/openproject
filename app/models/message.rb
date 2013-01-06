#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Message < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :board
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  acts_as_tree :counter_cache => :replies_count, :order => "#{Message.table_name}.created_on ASC"
  acts_as_attachable
  belongs_to :last_reply, :class_name => 'Message', :foreign_key => 'last_reply_id'

   acts_as_journalized :event_title => Proc.new {|o| "#{o.board.name}: #{o.subject}"},
                :event_description => :content,
                :event_type => Proc.new {|o| o.parent_id.nil? ? 'message' : 'reply'},
                :event_url => (Proc.new do |o|
                  msg = o.journaled
                  if msg.parent_id.nil?
                    {:id => msg.id}
                  else
                    {:id => msg.parent_id, :r => msg.id, :anchor => "message-#{msg.id}"}
                  end.reverse_merge :controller => 'messages', :action => 'show', :board_id => msg.board_id
                end),
                :activity_find_options => { :include => { :board => :project } },
                :except => [:last_reply_id, :replies_count]

  acts_as_searchable :columns => ['subject', 'content'],
                     :include => {:board => :project},
                     :project_key => 'project_id',
                     :date_column => "#{table_name}.created_on"

  acts_as_watchable

  validates_presence_of :board, :subject, :content
  validates_length_of :subject, :maximum => 255

  after_create :add_author_as_watcher

  named_scope :visible, lambda {|*args| { :include => {:board => :project},
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_messages) } }

  safe_attributes 'subject', 'content'
  safe_attributes 'locked', 'sticky', 'board_id',
    :if => lambda {|message, user|
      user.allowed_to?(:edit_messages, message.project)
    }

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_messages, project)
  end

  def validate_on_create
    # Can not reply to a locked topic
    errors.add_to_base 'Topic is locked' if root.locked? && self != root
  end

  def after_create
    if parent
      parent.reload.update_attribute(:last_reply_id, self.id)
    end
    board.reset_counters!
  end

  def after_update
    if board_id_changed?
      Message.update_all("board_id = #{board_id}", ["id = ? OR parent_id = ?", root.id, root.id])
      Board.reset_counters!(board_id_was)
      Board.reset_counters!(board_id)
    end
  end

  def after_destroy
    parent.reset_last_reply_id! if parent
    board.reset_counters!
  end

  def reset_last_reply_id!
    clid = children.present? ? children.last.id : nil
    self.update_attribute(:last_reply_id, clid)
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
    usr && usr.logged? && (usr.allowed_to?(:edit_messages, project) || (self.author == usr && usr.allowed_to?(:edit_own_messages, project)))
  end

  def destroyable_by?(usr)
    usr && usr.logged? && (usr.allowed_to?(:delete_messages, project) || (self.author == usr && usr.allowed_to?(:delete_own_messages, project)))
  end

  private

  def add_author_as_watcher
    Watcher.create(:watchable => self.root, :user => author)
  end
end
