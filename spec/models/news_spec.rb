#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
require "spec_helper"
require File.expand_path("../support/shared/become_member", __dir__)

require "support/shared/acts_as_watchable"

RSpec.describe News do
  include BecomeMember

  let(:project) do
    project = create(:public_project)
    project.enabled_modules << EnabledModule.new(name: "news")
    project.reload
  end

  let!(:news) { create(:news, project:) }
  let(:permissions) { [] }
  let(:role) { build(:project_role, permissions:) }

  it_behaves_like "acts_as_watchable included" do
    let(:model_instance) { create(:news) }
    let(:watch_permission) { :view_news }
    let(:project) { model_instance.project }
  end

  describe ".latest" do
    let(:project_news) { described_class.where(project:) }

    before do
      ProjectRole.anonymous
    end

    it "includes news elements from projects where news module is enabled" do
      expect(described_class.latest).to contain_exactly(news)
    end

    it "doesn't include news elements from projects where news module is not enabled" do
      EnabledModule.where(project_id: project.id, name: "news").delete_all

      expect(described_class.latest).to be_empty
    end

    it "only includes news elements from projects that are visible to the user" do
      private_project = create(:project, public: false)
      create(:news, project: private_project)

      latest_news = described_class.latest(user: User.anonymous)
      expect(latest_news).to contain_exactly(news)
    end

    it "limits the number of returned news elements" do
      project_news.delete_all

      create_list(:news, 10, project:)

      expect(project_news.latest(user: User.current, count:  2).size).to eq(2)
      expect(project_news.latest(user: User.current, count:  6).size).to eq(6)
      expect(project_news.latest(user: User.current, count: 15).size).to eq(10)
    end

    it "returns five news elements by default" do
      project_news.delete_all

      create_list(:news, 2, project:)

      expect(project_news.latest.size).to eq(2)

      create_list(:news, 3, project:)
      expect(project_news.latest.size).to eq(5)

      create_list(:news, 2, project:)
      expect(project_news.latest.size).to eq(5)
    end
  end

  describe "#save" do
    it "sends email notifications when created" do
      create(:user,
             member_with_roles: { project => role },
             notification_settings: [
               build(:notification_setting,
                     news_added: true)
             ])
      project.members.reload

      perform_enqueued_jobs do
        create(:news, project:)
      end
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end

  describe "#to_param" do
    it "includes includes id and title for a nicer url" do
      title = "OpenProject now has a Twitter Account"
      news  = create(:news, title:)
      slug  = "#{news.id}-openproject-now-has-a-twitter-account"

      expect(news.to_param).to eq slug
    end

    it "returns nil for unsaved news" do
      news = described_class.new
      expect(news.to_param).to be_nil
    end
  end

  describe "#new_comment" do
    subject(:comment) { news.new_comment(author: news.author, comments: "some important words") }

    it "sets the comment`s news" do
      expect(comment.commented)
        .to eq news
    end

    it "is saveable" do
      expect(comment.save)
        .to be_truthy
    end
  end

  describe "#comments_count" do
    it "counts the comments on the news when adding" do
      expect { news.comments.create(author: news.author, comments: "some important words") }
        .to change { news.reload.comments_count }
              .from(0)
              .to(1)
    end

    it "counts the comments on the news when destroying a comment" do
      comment = news.comments.build(author: news.author, comments: "some important words")
      comment.save

      expect { comment.destroy }
        .to change { news.reload.comments_count }
              .from(1)
              .to(0)
    end
  end
end
