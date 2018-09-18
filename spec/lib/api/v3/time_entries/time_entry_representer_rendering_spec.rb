#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
                             spent_on: Date.today,
                             created_on: DateTime.now - 6.hours,
                             updated_on: DateTime.now - 3.hours,
                             hours: 5,
                             activity: activity,
                             project: project,
                             user: user)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:work_package) { time_entry.work_package }
  let(:activity) { FactoryBot.build_stubbed(:time_entry_activity) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.create(time_entry, current_user: user, embed_links: true)
  end

  subject { representer.to_json }

  before do
    allow(time_entry)
      .to receive(:available_custom_fields)
      .and_return([])
  end

  include_context 'eager loaded work package representer'

  describe '_links' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.time_entry time_entry.id }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'project' }
      let(:href) { api_v3_paths.project project.id }
      let(:title) { project.name }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'workPackage' }
      let(:href) { api_v3_paths.work_package work_package.id }
      let(:title) { work_package.subject }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'user' }
      let(:href) { api_v3_paths.user user.id }
      let(:title) { user.name }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'activity' }
      let(:href) { api_v3_paths.time_entries_activity activity.id }
      let(:title) { activity.name }
    end

    context 'for a non shared (project specific) activity' do
      let(:activity) do
        activity = FactoryBot.build_stubbed(:time_entry_activity,
                                            project: project,
                                            parent: parent_activity)
        allow(activity)
          .to receive(:root)
          .and_return(parent_activity)

        activity
      end
      let(:parent_activity) do
        FactoryBot.build_stubbed(:time_entry_activity)
      end

      it_behaves_like 'has a titled link' do
        let(:link) { 'activity' }
        let(:href) { api_v3_paths.time_entries_activity parent_activity.id }
        let(:title) { parent_activity.name }
      end
    end

    context 'custom value' do
      let(:custom_field) do
        FactoryBot.build_stubbed(:time_entry_custom_field, field_format: 'user')
      end
      let(:custom_value) do
        CustomValue.new(custom_field: custom_field,
                        value: '1',
                        customized: time_entry)
      end
      let(:user) do
        FactoryBot.build_stubbed(:user)
      end

      before do
        allow(time_entry)
          .to receive(:available_custom_fields)
          .and_return([custom_field])

        allow(time_entry)
          .to receive(:"custom_field_#{custom_field.id}")
          .and_return(user)

        allow(time_entry)
          .to receive(:custom_value_for)
          .with(custom_field)
          .and_return(custom_value)
      end

      it 'has the user linked' do
        expect(subject)
          .to be_json_eql(api_v3_paths.user(custom_value.value).to_json)
          .at_path("_links/customField#{custom_field.id}/href")
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'TimeEntry' }
    end

    it_behaves_like 'property', :id do
      let(:value) { time_entry.id }
    end

    it_behaves_like 'property', :comment do
      let(:value) { time_entry.comments }
    end

    context 'with an empty comment' do
      let(:time_entry) { FactoryBot.build_stubbed(:time_entry) }
      it_behaves_like 'property', :comment do
        let(:value) { time_entry.comments }
      end
    end

    it_behaves_like 'date property', :spentOn do
      let(:value) { time_entry.spent_on }
    end

    it_behaves_like 'property', :hours do
      let(:value) { 'PT5H' }
    end

    it_behaves_like 'datetime property', :createdAt do
      let(:value) { time_entry.created_on }
    end

    it_behaves_like 'datetime property', :updatedAt do
      let(:value) { time_entry.updated_on }
    end

    context 'custom value' do
      let(:custom_field) { FactoryBot.build_stubbed(:time_entry_custom_field) }
      let(:custom_value) do
        CustomValue.new(custom_field: custom_field,
                        value: '1234',
                        customized: time_entry)
      end

      before do
        allow(time_entry)
          .to receive(:available_custom_fields)
          .and_return([custom_field])

        allow(time_entry)
          .to receive(:"custom_field_#{custom_field.id}")
          .and_return(custom_value.value)
      end

      it "has property for the custom field" do
        expected = {
          format: "markdown",
          html: "<p>#{custom_value.value}</p>",
          raw: custom_value.value
        }

        is_expected
          .to be_json_eql(expected.to_json)
          .at_path("customField#{custom_field.id}")
      end
    end
  end
end
