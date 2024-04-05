# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe "Progress modal", :js, :with_cuprite do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }

  shared_let(:estimated_hours) { 10.0 }
  shared_let(:remaining_hours) { 5.0 }
  shared_let(:work_package) do
    create(:work_package, project:) do |wp|
      update_work_package_with(wp, estimated_hours:, remaining_hours:)
    end
  end

  def update_work_package_with(work_package, attributes)
    WorkPackages::UpdateService.new(model: work_package,
                                    user:,
                                    contract_class: WorkPackages::CreateContract)
                               .call(**attributes)
  end

  current_user { user }

  let(:progress_query) do
    create(:query,
           project:,
           user:,
           display_sums: false,
           column_names: %i[id subject type status
                            estimated_hours remaining_hours done_ratio]) do |query|
      create(:view_work_packages_table, query:)
    end
  end
  let(:work_package_table) { Pages::WorkPackagesTable.new(project) }
  let(:work_package_row) { work_package_table.work_package_container(work_package) }

  describe "clicking on a field on the work package table" do
    it "opens the modal with its work field in focus " \
       "when clicking on the work input field" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      modal = work_edit_field.activate!

      modal.expect_modal_field_in_focus
    end

    it "sets the cursor after the last character on the selected input field" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      modal = work_edit_field.activate!

      modal.expect_cursor_at_end_of_input
    end
  end

  describe "clicking on the remaining work field on the work package table " \
           "with no fields set" do
    before do
      update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil)
    end

    it "opens the modal with work in focus and remaining work disabled" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      remaining_work_field = ProgressEditField.new(work_package_row, :remainingTime)

      remaining_work_field.activate!

      work_edit_field.expect_modal_field_in_focus
      remaining_work_field.expect_modal_field_disabled
    end
  end

  describe "opening the progress modal" do
    it "populates fields with correct values" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)
      percent_complete_edit_field = ProgressEditField.new(work_package_row, :percentageDone)

      work_edit_field.activate!

      work_edit_field.expect_modal_field_value(work_package.estimated_hours)
      remaining_work_edit_field.expect_modal_field_value(work_package.remaining_hours)
      percent_complete_edit_field.expect_modal_field_value(work_package.done_ratio)
    end

    it "disables the field that triggered the modal" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)

      work_edit_field.activate!

      work_edit_field.expect_trigger_field_disabled
    end

    it "allows clicking on a field other than the one that triggered the modal " \
       "and opens the modal with said field selected" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

      remaining_work_edit_field.activate!
      remaining_work_edit_field.expect_modal_field_in_focus
      remaining_work_edit_field.expect_trigger_field_disabled

      work_edit_field.reactivate!
      work_edit_field.expect_modal_field_in_focus
      work_edit_field.expect_trigger_field_disabled
    end
  end

  describe "% Complete field" do
    it "renders as readonly" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      percent_complete_edit_field = ProgressEditField.new(work_package_row, :percentageDone)

      work_edit_field.activate!

      percent_complete_edit_field.expect_read_only_modal_field
    end
  end
end
