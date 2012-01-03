#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class News < ActiveRecord::Base
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 60
  validates_length_of :summary, :maximum => 255

  acts_as_journalized :event_url => Proc.new {|o| {:controller => 'news', :action => 'show', :id => o.journaled_id} }
  acts_as_searchable :columns => ["#{table_name}.title", "#{table_name}.summary", "#{table_name}.description"], :include => :project
  acts_as_watchable

  after_create :add_author_as_watcher

  named_scope :visible, lambda {|*args| {
    :include => :project,
    :conditions => Project.allowed_to_condition(args.first || User.current, :view_news)
  }}

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end

  # returns latest news for projects visible by user
  def self.latest(user = User.current, count = 5)
    find(:all, :limit => count, :conditions => Project.allowed_to_condition(user, :view_news), :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
  end

  private

  def add_author_as_watcher
    Watcher.create(:watchable => self, :user => author)
  end
end
