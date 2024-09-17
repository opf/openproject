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

RSpec.describe Projects::Activity, "core" do
  shared_let(:project) do
    create(:project, :updated_a_long_time_ago)
  end

  let(:initial_time) { Time.current }

  let(:work_package) do
    create(:work_package,
           project:)
  end

  let(:work_package2) do
    create(:work_package,
           project:)
  end

  let(:wiki_page) do
    project.reload

    create(:wiki_page,
           wiki: project.wiki)
  end

  let(:wiki_page2) do
    project.reload

    create(:wiki_page,
           wiki: project.wiki)
  end

  let(:news) do
    create(:news,
           project:)
  end

  let(:news2) do
    create(:news,
           project:)
  end

  let(:repository) do
    create(:repository_git,
           project:)
  end

  let(:changeset) do
    create(:changeset,
           repository:)
  end

  let(:changeset2) do
    create(:changeset,
           repository:)
  end

  let(:forum) do
    create(:forum,
           project:)
  end

  let(:message) do
    create(:message,
           forum:)
  end

  let(:message2) do
    create(:message,
           forum:)
  end

  let(:time_entry) do
    create(:time_entry,
           work_package:,
           project:)
  end

  let(:time_entry2) do
    create(:time_entry,
           work_package:,
           project:)
  end

  def latest_activity
    Project.with_latest_activity.find(project.id).latest_activity_at
  end

  describe ".with_latest_activity" do
    it "is the latest work_package update" do
      work_package.update(updated_at: initial_time - 10.seconds)
      work_package2.update(updated_at: initial_time - 20.seconds)
      work_package.reload
      work_package2.reload

      # there is a loss of precision for timestamps stored in database
      expect(latest_activity).to equal_time_without_usec(work_package.updated_at)
    end

    it "is the latest wiki_pages update" do
      wiki_page.update(updated_at: initial_time - 10.seconds)
      wiki_page2.update(updated_at: initial_time - 20.seconds)
      wiki_page.reload
      wiki_page2.reload

      expect(latest_activity).to equal_time_without_usec(wiki_page.updated_at)
    end

    it "is the latest news update" do
      news.update(updated_at: initial_time - 10.seconds)
      news2.update(updated_at: initial_time - 20.seconds)
      news.reload
      news2.reload

      expect(latest_activity).to equal_time_without_usec(news.updated_at)
    end

    it "is the latest changeset update" do
      changeset.update(committed_on: initial_time - 10.seconds)
      changeset2.update(committed_on: initial_time - 20.seconds)
      changeset.reload
      changeset2.reload

      expect(latest_activity).to equal_time_without_usec(changeset.committed_on)
    end

    it "is the latest message update" do
      message.update(updated_at: initial_time - 10.seconds)
      message2.update(updated_at: initial_time - 20.seconds)
      message.reload
      message2.reload

      expect(latest_activity).to equal_time_without_usec(message.updated_at)
    end

    it "is the latest time_entry update" do
      work_package.update(updated_at: initial_time - 60.seconds)
      time_entry.update(updated_at: initial_time - 10.seconds)
      time_entry2.update(updated_at: initial_time - 20.seconds)
      time_entry.reload
      time_entry2.reload

      expect(latest_activity).to equal_time_without_usec(time_entry.updated_at)
    end

    it "is the latest project update" do
      work_package.update(updated_at: initial_time - 60.seconds)
      project.update(updated_at: initial_time - 10.seconds)

      expect(latest_activity).to equal_time_without_usec(project.updated_at)
    end

    it "takes the time stamp of the latest activity across models" do
      work_package.update(updated_at: initial_time - 10.seconds)
      wiki_page.update(updated_at: initial_time - 20.seconds)
      news.update(updated_at: initial_time - 30.seconds)
      changeset.update(committed_on: initial_time - 40.seconds)
      message.update(updated_at: initial_time - 50.seconds)
      project.update(updated_at: initial_time - 60.seconds)

      work_package.reload
      wiki_page.reload
      news.reload
      changeset.reload
      message.reload

      # Order:
      # work_package
      # wiki_page
      # news
      # changeset
      # message
      # project

      expect(latest_activity).to equal_time_without_usec(work_package.updated_at)

      work_package.update(updated_at: project.updated_at - 10.seconds)

      # Order:
      # wiki_page
      # news
      # changeset
      # message
      # project
      # work_package

      expect(latest_activity).to equal_time_without_usec(wiki_page.updated_at)

      wiki_page.update(updated_at: work_package.updated_at - 10.seconds)

      # Order:
      # news
      # changeset
      # message
      # project
      # work_package
      # wiki_page

      expect(latest_activity).to equal_time_without_usec(news.updated_at)

      news.update(updated_at: wiki_page.updated_at - 10.seconds)

      # Order:
      # changeset
      # message
      # project
      # work_package
      # wiki_page
      # news

      expect(latest_activity).to equal_time_without_usec(changeset.committed_on)

      changeset.update(committed_on: news.updated_at - 10.seconds)

      # Order:
      # message
      # project
      # work_package
      # wiki_page
      # news
      # changeset

      expect(latest_activity).to equal_time_without_usec(message.updated_at)

      message.update(updated_at: changeset.committed_on - 10.seconds)

      # Order:
      # project
      # work_package
      # wiki_page
      # news
      # changeset
      # message

      expect(latest_activity).to equal_time_without_usec(project.updated_at)
    end
  end
end
