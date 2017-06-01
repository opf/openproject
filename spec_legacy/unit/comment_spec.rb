#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe Comment, type: :model do
  include MiniTest::Assertions # refute

  it 'should validations' do
    # factory valid
    assert FactoryGirl.build(:comment).valid?

    # comment text required
    refute FactoryGirl.build(:comment, comments: '').valid?
    # object that is commented required
    refute FactoryGirl.build(:comment, commented: nil).valid?
    # author required
    refute FactoryGirl.build(:comment, author: nil).valid?
  end

  it 'should create' do
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    comment = Comment.new(commented: news, author: user, comments: 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  it 'should create through news' do
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    comment = news.new_comment(author: user, comments: 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  it 'should create comment through news' do
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    news.post_comment!(author: user, comments: 'some important words')
    assert_equal 1, news.reload.comments_count
  end

  it 'should text' do
    comment = FactoryGirl.build(:comment, comments: 'something useful')
    assert_equal 'something useful', comment.text
  end

  it 'should create should send notification with settings' do
    # news needs a project in order to be notified
    # see Redmine::Acts::Journalized::Deprecated#recipients
    project = FactoryGirl.create(:project)
    user = FactoryGirl.create(:user, member_in_project: project)
    # author is automatically added as watcher
    # this makes #user to receive a notification
    news = FactoryGirl.create(:news, project: project, author: user)

    # with notifications for that event turned on
    allow(Setting).to receive(:notified_events).and_return(['news_comment_added'])
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      Comment.create!(commented: news, author: user, comments: 'more useful stuff')
    end

    # with notifications for that event turned off
    allow(Setting).to receive(:notified_events).and_return([])
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      Comment.create!(commented: news, author: user, comments: 'more useful stuff')
    end
  end

  # TODO: testing #destroy really needed?
  it 'should destroy' do
    # just setup
    news = FactoryGirl.create(:news)
    comment = FactoryGirl.build(:comment)
    news.comments << comment
    assert comment.persisted?

    # #reload is needed to refresh the count
    assert_equal 1, news.reload.comments_count
    comment.destroy
    assert_equal 0, news.reload.comments_count
  end
end
