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

require 'spec_helper'

describe Project::Activity, type: :model do
  let(:project) {
    FactoryGirl.create(:project)
  }

  let(:initial_time) { Time.now }

  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project)
  }

  let(:work_package2) {
    FactoryGirl.create(:work_package,
                       project: project)
  }

  let(:wiki_content) {
    project.reload

    page = FactoryGirl.create(:wiki_page,
                              wiki: project.wiki)

    FactoryGirl.create(:wiki_content,
                       page: page)
  }

  let(:wiki_content2) {
    project.reload

    page = FactoryGirl.create(:wiki_page,
                              wiki: project.wiki)

    FactoryGirl.create(:wiki_content,
                       page: page)
  }

  let(:news) {
    FactoryGirl.create(:news,
                       project: project)
  }

  let(:news2) {
    FactoryGirl.create(:news,
                       project: project)
  }

  let(:repository) {
    FactoryGirl.create(:repository_git,
                       project: project)
  }

  let(:changeset) {
    FactoryGirl.create(:changeset,
                       repository: repository)
  }

  let(:changeset2) {
    FactoryGirl.create(:changeset,
                       repository: repository)
  }

  let(:board) {
    FactoryGirl.create(:board,
                       project: project)
  }

  let(:message) {
    FactoryGirl.create(:message,
                       board: board)
  }

  let(:message2) {
    FactoryGirl.create(:message,
                       board: board)
  }

  let(:time_entry) {
    FactoryGirl.create(:time_entry,
                       work_package: work_package,
                       project: project)
  }

  let(:time_entry2) {
    FactoryGirl.create(:time_entry,
                       work_package: work_package,
                       project: project)
  }

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
      news.update_attribute(:created_on, initial_time - 10.seconds)
      news2.update_attribute(:created_on, initial_time - 20.seconds)
      news.reload
      news2.reload

      expect(latest_activity).to eql news.created_on
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
      news.update_attribute(:created_on, initial_time - 30.seconds)
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

      expect(latest_activity).to eql news.created_on

      news.update_attribute(:created_on, wiki_content.updated_on - 10.seconds)

      # Order:
      # changeset
      # message
      # work_package
      # wiki_content
      # news

      expect(latest_activity).to eql changeset.committed_on

      changeset.update_attribute(:committed_on, news.created_on - 10.seconds)

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
