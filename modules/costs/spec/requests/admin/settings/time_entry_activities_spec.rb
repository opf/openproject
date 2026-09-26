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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Time entry activities", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "PUT /admin/settings/time_entry_activities/:id/move" do
    let!(:first_record) { create(:time_entry_activity, name: "Alpha") }
    let!(:second_record) { create(:time_entry_activity, name: "Beta") }
    let!(:third_record) { create(:time_entry_activity, name: "Gamma") }
    let!(:sibling_record) { create(:issue_priority) }
    let(:list_type) { "time_entry_activity" }
    let(:morph_target) { "admin-enumerations-index-component" }

    before do
      third_record.move_to_top
      second_record.move_to_top
      first_record.move_to_top
    end

    def move_path(record)
      move_admin_settings_time_entry_activity_path(record)
    end

    def ordered_names
      TimeEntryActivity.reorder(:position).where(name: %w[Alpha Beta Gamma]).pluck(:name)
    end

    it_behaves_like "an anchor-only enumeration move endpoint"
    # IssuePriority and TimeEntryActivity are STI siblings on the enumerations table.
    it_behaves_like "an enumeration move endpoint refusing sibling-class anchors"
  end
end
