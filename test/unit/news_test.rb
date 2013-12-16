#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require File.expand_path('../../test_helper', __FILE__)

class NewsTest < ActiveSupport::TestCase
  fixtures :all

  def valid_news
    { :title => 'Test news', :description => 'Lorem ipsum etc', :author => User.find(:first) }
  end

  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Setting.notified_events.dup << 'news_added'
    news = Project.find(:first).news.new(valid_news)

    assert news.save
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_should_include_news_for_projects_with_news_enabled
    project = projects(:projects_001)
    assert project.enabled_modules.any?{ |em| em.name == 'news' }

    # News.latest should return news from projects_001
    assert News.latest.any? { |news| news.project == project }
  end

  def test_should_not_include_news_for_projects_with_news_disabled
    EnabledModule.delete_all(["project_id = ? AND name = ?", 2, 'news'])
    project = Project.find(2)

    # Add a piece of news to the project
    news = project.news.create(valid_news)

    # News.latest should not return that new piece of news
    assert News.latest.include?(news) == false
  end

  def test_should_only_include_news_from_projects_visibly_to_the_user
    assert News.latest(User.anonymous).all? { |news| news.project.is_public? }
  end

  def test_should_limit_the_amount_of_returned_news
    # Make sure we have a bunch of news stories
    10.times { projects(:projects_001).news.create(valid_news) }
    assert_equal 2, News.latest(users(:users_002), 2).size
    assert_equal 6, News.latest(users(:users_002), 6).size
  end

  def test_should_return_5_news_stories_by_default
    # Make sure we have a bunch of news stories
    10.times { projects(:projects_001).news.create(valid_news) }
    assert_equal 5, News.latest(users(:users_004)).size
  end

  def test_to_param_should_include_id_and_title
    title = "OpenProject now has a Twitter Account"
    news  = News.create! valid_news.merge(:title => title)
    assert_equal news.to_param, "#{news.id}-openproject-now-has-a-twitter-account"
  end

  def test_to_param_should_return_nil_for_unsaved_news
    assert_nil News.new.to_param
  end
end
