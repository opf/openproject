# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe "Time entry timer change announcement", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages log_own_time view_own_time_entries edit_own_time_entries]
           })
  end

  current_user { user }

  def expect_timer_change_announced
    expect(response.body).to have_turbo_stream(action: "dispatchEvent") do |streams|
      expect(streams.first["event-name"]).to eq(My::Timer::MenuSectionComponent::CHANGED_EVENT)
    end
  end

  def expect_no_timer_change_announced
    expect(response.body).not_to include(My::Timer::MenuSectionComponent::CHANGED_EVENT)
  end

  context "with a running timer" do
    let!(:timer) { create(:time_entry, user:, entity: work_package, project:, ongoing: true, hours: nil) }

    it "announces the change when the timer is stopped" do
      patch time_entry_path(timer),
            params: { time_entry: { ongoing: false, hours: "1" } },
            as: :turbo_stream

      expect(timer.reload).not_to be_ongoing
      expect_timer_change_announced
    end

    it "announces the change when the timer is deleted" do
      delete time_entry_path(timer), as: :turbo_stream

      expect(TimeEntry).not_to exist(timer.id)
      expect_timer_change_announced
    end
  end

  context "with a finished time entry" do
    let!(:time_entry) { create(:time_entry, user:, entity: work_package, project:, hours: 2) }

    it "stays quiet when it is updated" do
      patch time_entry_path(time_entry),
            params: { time_entry: { hours: "3" } },
            as: :turbo_stream

      expect(time_entry.reload.hours).to eq 3
      expect_no_timer_change_announced
    end
  end
end
