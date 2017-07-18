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

describe ::API::V3::TimeEntries::TimeEntryRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:time_entry) do
    FactoryGirl.build_stubbed(:time_entry,
                              comments: 'blubs',
                              spent_on: Date.today,
                              created_on: DateTime.now - 6.hours,
                              updated_on: DateTime.now - 3.hours,
                              hours: 5,
                              activity: activity,
                              project: project,
                              user: user)
  end
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:work_package) { time_entry.work_package }
  let(:activity) { FactoryGirl.build_stubbed(:time_entry_activity) }
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:representer) do
    described_class.new(time_entry, current_user: user, embed_links: true)
  end

  subject { representer.to_json }

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
        activity = FactoryGirl.build_stubbed(:time_entry_activity,
                                             project: project,
                                             parent: parent_activity)
        allow(activity)
          .to receive(:root)
          .and_return(parent_activity)

        activity
      end
      let(:parent_activity) do
        FactoryGirl.build_stubbed(:time_entry_activity)
      end

      it_behaves_like 'has a titled link' do
        let(:link) { 'activity' }
        let(:href) { api_v3_paths.time_entries_activity parent_activity.id }
        let(:title) { parent_activity.name }
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
      let(:time_entry) { FactoryGirl.build_stubbed(:time_entry) }
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
  end
end
