#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require 'spec_helper'
require File.expand_path('../support/shared/become_member', __dir__)

require 'support/shared/acts_as_watchable'

describe News, type: :model do
  include BecomeMember

  let(:project) do
    project = create(:public_project)
    project.enabled_modules << EnabledModule.new(name: 'news')
    project.reload
  end

  let!(:news) { create(:news, project: project) }
  let(:permissions) { [] }
  let(:role) { build(:role, permissions: permissions) }

  it_behaves_like 'acts_as_watchable included' do
    let(:model_instance) { create(:news) }
    let(:watch_permission) { :view_news }
    let(:project) { model_instance.project }
  end

  describe '.latest' do
    let(:project_news) { News.where(project: project) }

    before do
      Role.anonymous
    end

    it 'includes news elements from projects where news module is enabled' do
      expect(News.latest).to match_array [news]
    end

    it "doesn't include news elements from projects where news module is not enabled" do
      EnabledModule.where(project_id: project.id, name: 'news').delete_all

      expect(News.latest).to be_empty
    end

    it 'only includes news elements from projects that are visible to the user' do
      private_project = create(:project, public: false)
      create(:news, project: private_project)

      latest_news = News.latest(user: User.anonymous)
      expect(latest_news).to match_array [news]
    end

    it 'limits the number of returned news elements' do
      project_news.delete_all

      10.times do
        create(:news, project: project)
      end

      expect(project_news.latest(user: User.current, count:  2).size).to eq(2)
      expect(project_news.latest(user: User.current, count:  6).size).to eq(6)
      expect(project_news.latest(user: User.current, count: 15).size).to eq(10)
    end

    it 'returns five news elements by default' do
      project_news.delete_all

      2.times do
        create(:news, project: project)
      end

      expect(project_news.latest.size).to eq(2)

      3.times do
        create(:news, project: project)
      end
      expect(project_news.latest.size).to eq(5)

      2.times do
        create(:news, project: project)
      end
      expect(project_news.latest.size).to eq(5)
    end
  end

  describe '#save' do
    it 'sends email notifications when created' do
      create(:user,
                        member_in_project: project,
                        member_through_role: role)
      project.members.reload

      perform_enqueued_jobs do
        create(:news, project: project)
      end
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end

  describe '#to_param' do
    it 'includes includes id and title for a nicer url' do
      title = 'OpenProject now has a Twitter Account'
      news  = create(:news, title: title)
      slug  = "#{news.id}-openproject-now-has-a-twitter-account"

      expect(news.to_param).to eq slug
    end

    it 'returns nil for unsaved news' do
      news = News.new
      expect(news.to_param).to be_nil
    end
  end
end
