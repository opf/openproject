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

require 'spec_helper'

describe Projects::Activity, type: :model do
  let(:project) do
    FactoryBot.create(:project)
  end

  let(:initial_time) { Time.now }

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project: project)
  end

  let(:work_package2) do
    FactoryBot.create(:work_package,
                      project: project)
  end

  let(:wiki_content) do
    project.reload

    page = FactoryBot.create(:wiki_page,
                             wiki: project.wiki)

    FactoryBot.create(:wiki_content,
                      page: page)
  end

  let(:wiki_content2) do
    project.reload

    page = FactoryBot.create(:wiki_page,
                             wiki: project.wiki)

    FactoryBot.create(:wiki_content,
                      page: page)
  end

  let(:news) do
    FactoryBot.create(:news,
                      project: project)
  end

  let(:news2) do
    FactoryBot.create(:news,
                      project: project)
  end

  let(:repository) do
    FactoryBot.create(:repository_git,
                      project: project)
  end

  let(:changeset) do
    FactoryBot.create(:changeset,
                      repository: repository)
  end

  let(:changeset2) do
    FactoryBot.create(:changeset,
                      repository: repository)
  end

  let(:forum) do
    FactoryBot.create(:forum,
                      project: project)
  end

  let(:message) do
    FactoryBot.create(:message,
                      forum: forum)
  end

  let(:message2) do
    FactoryBot.create(:message,
                      forum: forum)
  end

  let(:time_entry) do
    FactoryBot.create(:time_entry,
                      work_package: work_package,
                      project: project)
  end

  let(:time_entry2) do
    FactoryBot.create(:time_entry,
                      work_package: work_package,
                      project: project)
  end

  def latest_activity
    Project.with_latest_activity.find(project.id).latest_activity_at
  end

  describe '.with_latest_activity' do
    it 'is the latest work_package update' do
      work_package.update_attribute(:updated_at, initial_time - 10.seconds)
      work_package2.update_attribute(:updated_at, initial_time - 20.seconds)
      work_package.reload
      work_package2.reload

      expect(latest_activity).to eql work_package.updated_at
    end

    it 'is the latest wiki_contents update' do
      wiki_content.update_attribute(:updated_on, initial_time - 10.seconds)
      wiki_content2.update_attribute(:updated_on, initial_time - 20.seconds)
      wiki_content.reload
      wiki_content2.reload

      expect(latest_activity).to eql wiki_content.updated_on
    end

    it 'is the latest news update' do
      news.update_attribute(:updated_at, initial_time - 10.seconds)
      news2.update_attribute(:updated_at, initial_time - 20.seconds)
      news.reload
      news2.reload

      expect(latest_activity).to eql news.updated_at
    end

    it 'is the latest changeset update' do
      changeset.update_attribute(:committed_on, initial_time - 10.seconds)
      changeset2.update_attribute(:committed_on, initial_time - 20.seconds)
      changeset.reload
      changeset2.reload

      expect(latest_activity).to eql changeset.committed_on
    end

    it 'is the latest message update' do
      message.update_attribute(:updated_on, initial_time - 10.seconds)
      message2.update_attribute(:updated_on, initial_time - 20.seconds)
      message.reload
      message2.reload

      expect(latest_activity).to eql message.updated_on
    end

    it 'is the latest time_entry update' do
      work_package.update_attribute(:updated_at, initial_time - 60.seconds)
      time_entry.update_attribute(:updated_on, initial_time - 10.seconds)
      time_entry2.update_attribute(:updated_on, initial_time - 20.seconds)
      time_entry.reload
      time_entry2.reload

      expect(latest_activity).to eql time_entry.updated_on
    end

    it 'takes the time stamp of the latest activity across models' do
      work_package.update_attribute(:updated_at, initial_time - 10.seconds)
      wiki_content.update_attribute(:updated_on, initial_time - 20.seconds)
      news.update_attribute(:updated_at, initial_time - 30.seconds)
      changeset.update_attribute(:committed_on, initial_time - 40.seconds)
      message.update_attribute(:updated_on, initial_time - 50.seconds)

      work_package.reload
      wiki_content.reload
      news.reload
      changeset.reload
      message.reload

      # Order:
      # work_package
      # wiki_content
      # news
      # changeset
      # message

      expect(latest_activity).to eql work_package.updated_at

      work_package.update_attribute(:updated_at, message.updated_on - 10.seconds)

      # Order:
      # wiki_content
      # news
      # changeset
      # message
      # work_package

      expect(latest_activity).to eql wiki_content.updated_on

      wiki_content.update_attribute(:updated_on, work_package.updated_at - 10.seconds)

      # Order:
      # news
      # changeset
      # message
      # work_package
      # wiki_content

      expect(latest_activity).to eql news.updated_at

      news.update_attribute(:updated_at, wiki_content.updated_on - 10.seconds)

      # Order:
      # changeset
      # message
      # work_package
      # wiki_content
      # news

      expect(latest_activity).to eql changeset.committed_on

      changeset.update_attribute(:committed_on, news.updated_at - 10.seconds)

      # Order:
      # message
      # work_package
      # wiki_content
      # news
      # changeset

      expect(latest_activity).to eql message.updated_on
    end
  end
end
