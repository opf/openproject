#-- encoding: UTF-8
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

describe TimeEntryActivity, type: :model do
  let(:activity) { FactoryBot.create(:time_entry_activity) }
  let(:project) { FactoryBot.create(:project) }
  let(:other_project) { FactoryBot.create(:project) }

  describe '.in_project' do
    context 'without a project configuration' do
      context 'with the activity being active' do
        it 'includes the activity' do
          expect(TimeEntryActivity.in_project(project))
            .to match_array [activity]
        end
      end

      context 'with the activity being inactive' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'excludes the activity' do
          expect(TimeEntryActivity.in_project(project))
            .to be_empty
        end
      end
    end

    context 'with a project configuration configured to true' do
      before do
        activity.time_entry_activities_projects.create(project: project, active: true)
      end

      it 'includes the activity' do
        expect(TimeEntryActivity.in_project(project))
          .to match_array [activity]
      end

      context 'with the activity being inactive' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'includes the activity' do
          expect(TimeEntryActivity.in_project(project))
            .to match_array [activity]
        end
      end
    end

    context 'with a project configuration configured to false but for a different project' do
      before do
        activity.time_entry_activities_projects.create(project: other_project, active: false)
      end

      it 'includes the activity' do
        expect(TimeEntryActivity.in_project(project))
          .to match_array [activity]
      end
    end

    context 'with a project configuration configured to false' do
      before do
        activity.time_entry_activities_projects.create(project: project, active: false)
      end

      it 'excludes the activity' do
        expect(TimeEntryActivity.in_project(project))
          .to be_empty
      end
    end
  end

  describe '#activated_projects' do
    before do
      project
      other_project
    end

    context 'without project specific overrides' do
      context 'and being active' do
        it 'returns all projects' do
          expect(activity.activated_projects)
            .to match_array [project, other_project]
        end
      end

      context 'and not being active' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'returns no projects' do
          expect(activity.activated_projects)
            .to be_empty
        end
      end
    end

    context 'with project specific overrides' do
      before do
        TimeEntryActivitiesProject.insert(activity_id: activity.id, project_id: project.id, active: true)
        TimeEntryActivitiesProject.insert(activity_id: activity.id, project_id: other_project.id, active: false)
      end

      context 'and being active' do
        it 'returns the project the activity is activated in' do
          expect(activity.activated_projects)
            .to match_array [project]
        end
      end

      context 'and not being active' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'returns only the projects the activity is activated in' do
          expect(activity.activated_projects)
            .to match_array [project]
        end
      end
    end
  end
end
