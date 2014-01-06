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
require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe News do
  include BecomeMember

  before do
    Project.delete_all
    News.delete_all
  end

  let(:project) {
    project = FactoryGirl.create(:project)
    project.enabled_modules << EnabledModule.new(name: 'news')
    project.reload
  }

  let!(:news) { FactoryGirl.create(:news, project: project) }

  describe ".latest" do
    it "includes news elements from projects where news module is enabled" do
      expect(News.latest).to include news
    end

    it "doesn't include news elements from projects where news module is not enabled" do
      EnabledModule.delete_all(["project_id = ? AND name = ?", project.id, 'news'])
      project.reload

      expect(News.latest).to_not include news
    end

    it "only includes news elements from projects that are visible to the user" do
      private_project = FactoryGirl.create(:project, is_public: false)
      private_news    = FactoryGirl.create(:news, project: private_project)

      latest_news = News.latest(User.anonymous)
      expect(latest_news).to     include news
      expect(latest_news).to_not include private_news
    end

    it "limits the number of returned news elements" do
      News.delete_all

      10.times { FactoryGirl.create(:news) }

      expect(News.latest(User.current,  2)).to have(2).elements
      expect(News.latest(User.current,  6)).to have(6).elements
      expect(News.latest(User.current, 15)).to have(10).elements
    end

    it "returns five news elements by default" do
      News.delete_all

      2.times { FactoryGirl.create(:news) }
      expect(News.latest).to have(2).elements

      3.times { FactoryGirl.create(:news) }
      expect(News.latest).to have(5).elements

      2.times { FactoryGirl.create(:news) }
      expect(News.latest).to have(5).elements
    end
  end

  describe "#save" do
    it "sends email notifications when created" do
      ActionMailer::Base.deliveries.clear

      user = FactoryGirl.create(:user)
      become_member_with_permissions(project, user)

      with_settings notified_events: ['news_added'] do
        FactoryGirl.create(:news, project: project)
        expect(ActionMailer::Base.deliveries).to have(1).element
      end
    end
  end

  describe "#to_param" do
    it "includes includes id and title for a nicer url" do
      title = "OpenProject now has a Twitter Account"
      news  = FactoryGirl.create(:news, title: title)
      slug  = "#{news.id}-openproject-now-has-a-twitter-account"

      expect(news.to_param).to eq slug
    end

    it "returns nil for unsaved news" do
      news = News.new
      expect(news.to_param).to be_nil
    end
  end
end
