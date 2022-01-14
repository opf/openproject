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
require_relative './shared_context'

describe 'Team planner error handling', type: :feature, js: true do
  include_context 'with team planner full access'

  let!(:first_wp) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      assigned_to: user,
                      start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
                      due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday)
  end

  let!(:custom_field) do
    FactoryBot.create(:work_package_custom_field,
                      default_value: nil,
                      is_for_all: true,
                      is_required: false)
  end

  let(:type) { FactoryBot.create(:type, custom_fields: [custom_field]) }

  context 'with full permissions' do
    before do
      project.types << type
      project.save!

      custom_field.is_required = true
      custom_field.save!

      team_planner.visit!

      team_planner.add_assignee user

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp, present: true
      end
    end

    it 'cannot change the wp because of required fields not being set' do
      # Try to move the wp
      retry_block do
        team_planner.drag_wp_by_pixel(first_wp, 150, 0)
      end
      team_planner.expect_toast(type: :error, message: 'Custom Field Nr. 1 can\'t be blank')

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
      end
    end
  end
end
