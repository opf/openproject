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

describe TimeEntry, type: :model do
  let(:activity) do
    FactoryBot.build(:time_entry_activity)
  end

  describe '#activated_projects' do
    let(:project1) { FactoryBot.create(:project) }

    context 'project specific activity' do
      before do
        activity.project = project1
        activity.save!
      end

      context 'when the activity is active' do
        it 'returns the project if the activity is active' do
          expect(activity.activated_projects)
            .to match_array [project1]
        end
      end

      context 'when the activity is inactive' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'is empty if the activity is inactive' do
          expect(activity.activated_projects)
            .to be_empty
        end
      end
    end

    context 'system activity' do
      let(:project2) { FactoryBot.create(:project) }
      let(:project3) { FactoryBot.create(:project) }

      let(:child_activity_active) do
        FactoryBot.create(:time_entry_activity,
                          parent: activity,
                          project: project1)
      end
      let(:child_activity_inactive) do
        FactoryBot.create(:time_entry_activity,
                          parent: activity,
                          project: project2,
                          active: false)
      end

      before do
        child_activity_active
        child_activity_inactive
        project3
      end

      context 'when the activity is active' do
        before do
          activity.active = true
          activity.save!
        end

        it 'returns all projects except for those that have inactive child activities' do
          expect(activity.activated_projects)
            .to match_array([project1, project3])
        end
      end

      context 'when the activity is inactive' do
        before do
          activity.active = false
          activity.save!
        end

        it 'returns only those projects, that have active child activities' do
          expect(activity.activated_projects)
            .to match_array([project1])
        end
      end
    end
  end
end
