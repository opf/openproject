#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

class News < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  attr_protected :project_id, :author_id

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 60
  validates_length_of :summary, :maximum => 255

  acts_as_journalized

  acts_as_event url: Proc.new {|o| {:controller => '/news', :action => 'show', :id => o.id } },
                datetime: :created_on

  acts_as_searchable :columns => ["#{table_name}.title", "#{table_name}.summary", "#{table_name}.description"], :include => :project

  acts_as_watchable

  after_create :add_author_as_watcher

  needs_authorization view: :view_news

  safe_attributes 'title', 'summary', 'description'

  # returns latest news for projects visible by user
  def self.latest(user = User.current, count = 5)
    visible(user).limit(count)
                 .includes(:author, :project)
                 .newest_first
  end

  def self.latest_for(user, options = {})
    # TODO: probably #latest and latest_for can be consolidated
    limit = options.fetch(:count) { 5 }

    latest(user, limit)
  end

  # table_name shouldn't be needed :(
  def self.newest_first
    # should be able to use
    # order(created_on: :desc)
    # when on rails 4
    order "#{table_name}.created_on DESC"
  end

  def new_comment(attributes = {})
    comments.build(attributes)
  end

  def post_comment!(attributes = {})
    new_comment(attributes).post!
  end

  def to_param
    id && "#{id} #{title}".parameterize
  end

  private

  def add_author_as_watcher
    Watcher.create(:watchable => self, :user => author)
  end
end
