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

describe ::API::V3::TimeEntries::TimeEntryRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:time_entry) do
    FactoryBot.build_stubbed(:time_entry,
                             comments: 'blubs',
                             spent_on: Date.today - 3.days,
                             created_on: DateTime.now - 6.hours,
                             updated_on: DateTime.now - 3.hours,
                             activity: activity,
                             project: project,
                             user: user)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:project2) { FactoryBot.build_stubbed(:project) }
  let(:work_package) { time_entry.work_package }
  let(:work_package2) { FactoryBot.build_stubbed(:work_package) }
  let(:activity) { FactoryBot.build_stubbed(:time_entry_activity) }
  let(:activity2) { FactoryBot.build_stubbed(:time_entry_activity) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:user2) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.create(time_entry, current_user: user, embed_links: true)
  end
  let(:custom_field13) do
    FactoryBot.build_stubbed(:time_entry_custom_field, field_format: 'user', id: 13)
  end
  let(:custom_field11) do
    FactoryBot.build_stubbed(:time_entry_custom_field, field_format: 'text', id: 11)
  end

  let(:hash) do
    {
      "_links" => {
        "project" => {
          "href" => api_v3_paths.project(project2.id)
        },
        "activity" => {
          "href" => api_v3_paths.time_entries_activity(activity2.id)
        },
        "workPackage" => {
          "href" => api_v3_paths.work_package(work_package2.id)

        },
        "customField13" => {
          "href" => api_v3_paths.user(user2.id)
        }
      },
      "hours" => 'PT5H',
      "comment" => {
        "raw" => "some comment"
      },
      "spentOn" => "2017-07-28",
      "customField11" => {
        "raw" => "some text"
      }
    }
  end

  before do
    allow(time_entry)
      .to receive(:available_custom_fields)
      .and_return([custom_field11, custom_field13])
  end

  describe '_links' do
    context 'activity' do
      it 'updates the activity' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.activity_id)
          .to eql(activity2.id)
      end
    end

    context 'project' do
      it 'updates the project' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.project_id)
          .to eql(project2.id)
      end
    end

    context 'workPackage' do
      it 'updates the work_package' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.work_package_id)
          .to eql(work_package2.id)
      end
    end

    context 'linked custom field' do
      it 'updates the custom value' do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == custom_field13.id }.value)
          .to eql(user2.id.to_s)
      end
    end
  end

  describe 'properties' do
    context 'spentOn' do
      it 'updates spent_on' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.spent_on)
          .to eql(Date.parse("2017-07-28"))
      end
    end

    context 'hours' do
      it 'updates hours' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.hours)
          .to eql(5.0)
      end

      context 'with null value' do
        let(:hash) do
          {
            "hours" => nil
          }
        end

        it 'updates hours' do
          time_entry = representer.from_hash(hash)
          expect(time_entry.hours)
            .to eql(nil)
        end
      end
    end

    context 'comment' do
      it 'updates comment' do
        time_entry = representer.from_hash(hash)
        expect(time_entry.comments)
          .to eql('some comment')
      end
    end

    context 'property custom field' do
      it 'updates the custom value' do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == custom_field11.id }.value)
          .to eql("some text")
      end
    end
  end
end
