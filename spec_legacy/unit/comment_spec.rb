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
require 'legacy_spec_helper'

describe Comment, type: :model do
  include MiniTest::Assertions # refute

  it 'should validations' do
    # factory valid
    assert FactoryBot.build(:comment).valid?

    # comment text required
    refute FactoryBot.build(:comment, comments: '').valid?
    # object that is commented required
    refute FactoryBot.build(:comment, commented: nil).valid?
    # author required
    refute FactoryBot.build(:comment, author: nil).valid?
  end

  it 'should create' do
    user = FactoryBot.create(:user)
    news = FactoryBot.create(:news)
    comment = Comment.new(commented: news, author: user, comments: 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  it 'should create through news' do
    user = FactoryBot.create(:user)
    news = FactoryBot.create(:news)
    comment = news.new_comment(author: user, comments: 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  it 'should create comment through news' do
    user = FactoryBot.create(:user)
    news = FactoryBot.create(:news)
    news.post_comment!(author: user, comments: 'some important words')
    assert_equal 1, news.reload.comments_count
  end

  it 'should text' do
    comment = FactoryBot.build(:comment, comments: 'something useful')
    assert_equal 'something useful', comment.text
  end

  it 'should create should send notification with settings' do
    # news needs a project in order to be notified
    # see Redmine::Acts::Journalized::Deprecated#recipients
    project = FactoryBot.create(:project)
    user = FactoryBot.create(:user, member_in_project: project)
    # author is automatically added as watcher
    # this makes #user to receive a notification
    news = FactoryBot.create(:news, project: project, author: user)

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
    news = FactoryBot.create(:news)
    comment = FactoryBot.build(:comment)
    news.comments << comment
    assert comment.persisted?

    # #reload is needed to refresh the count
    assert_equal 1, news.reload.comments_count
    comment.destroy
    assert_equal 0, news.reload.comments_count
  end
end
