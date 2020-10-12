#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class News < ApplicationRecord
  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_many :comments, -> {
    order('created_on')
  }, as: :commented, dependent: :delete_all

  validates_presence_of :title
  validates_length_of :title, maximum: 60
  validates_length_of :summary, maximum: 255

  acts_as_journalized

  acts_as_event url: Proc.new { |o| { controller: '/news', action: 'show', id: o.id } },
                datetime: :created_at

  acts_as_searchable columns: ["#{table_name}.title", "#{table_name}.summary", "#{table_name}.description"],
                     include: :project,
                     references: :projects,
                     date_column: "#{table_name}.created_at"

  acts_as_watchable

  after_create :add_author_as_watcher,
               :send_news_added_mail

  scope :visible, ->(*args) do
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_news))
  end

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end

  def description=(val)
    super val.presence || ''
  end

  # returns latest news for projects visible by user
  def self.latest(user: User.current, count: 5)
    latest_for(user, count: count)
  end

  def self.latest_for(user, count: 5)
    scope = newest_first
            .includes(:author)
            .visible(user)

    if count > 0
      scope.limit(count)
    else
      scope
    end
  end

  # table_name shouldn't be needed :(
  def self.newest_first
    order "#{table_name}.created_at DESC"
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
    Watcher.create(watchable: self, user: author)
  end

  def send_news_added_mail
    if Setting.notified_events.include?('news_added')
      recipients.uniq.each do |user|
        UserMailer.news_added(user, self, User.current).deliver_later
      end
    end
  end
end
