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

RSpec.describe WorkPackages::ProgressController do
  shared_let(:work_package) { create(:work_package) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             work_package.project => %i[add_work_packages edit_work_packages view_work_packages]
           })
  end

  current_user { user }

  def progress_errors(work_package)
    work_package.errors.group_by_attribute.slice(:estimated_hours, :remaining_hours, :done_ratio)
  end

  # Gets the html content of the template of the first turbo-stream with the
  # given action.
  def turbo_stream_template(action:)
    assert_select("turbo-stream[action=#{action}] template").first.inner_html
  end

  describe "GET /work_packages/progress/new" do
    let(:params) do
      {
        "work_package" => {
          "initial" => {
            "estimated_hours" => "7.0",
            "remaining_hours" => "7.0",
            "done_ratio" => "0"
          },
          "estimated_hours" => "7h",
          "remaining_hours" => "7h",
          "done_ratio" => "0",
          "estimated_hours_touched" => "false",
          "remaining_hours_touched" => "false",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "assigns work package initialized with initial values and updated with touched and derived values" do
      params["work_package"]["estimated_hours"] = "5" # won't be used because not touched
      params["work_package"]["remaining_hours"] = "3"
      params["work_package"]["remaining_hours_touched"] = "true"

      get("new", params:)

      assigned_work_package = assigns(:work_package)
      expect(assigned_work_package).to be_new_record
      expect(assigned_work_package.estimated_hours).to eq(7)
      expect(assigned_work_package.remaining_hours).to eq(3)
      expect(assigned_work_package.done_ratio).to eq(57) # derived
      expect(progress_errors(assigned_work_package)).to be_empty
    end

    context "when the user edits fields and does not have 'Add work packages' permission" do
      before do
        RolePermission.where(permission: "add_work_packages").delete_all
      end

      it "displays read-only errors" do
        params["work_package"]["remaining_hours"] = "3"
        params["work_package"]["remaining_hours_touched"] = "true"

        get("new", params:)

        assigned_work_package = assigns(:work_package)
        expect(progress_errors(assigned_work_package)).to match(
          remaining_hours: [have_attributes(class: ActiveModel::Error, type: :error_readonly)]
        )
      end
    end

    context "when the user edits fields and does not have 'Edit work packages' permission" do
      before do
        RolePermission.where(permission: "edit_work_packages").delete_all
      end

      it "does not display any errors" do
        params["work_package"]["remaining_hours"] = "3"
        params["work_package"]["remaining_hours_touched"] = "true"

        get("new", params:)

        assigned_work_package = assigns(:work_package)
        expect(progress_errors(assigned_work_package)).to be_empty
      end
    end
  end

  describe "GET /work_packages/:id/progress" do
    let(:params) do
      {
        "work_package_id" => work_package.id,
        "work_package" => {
          "estimated_hours" => "42",
          "remaining_hours" => "4h",
          "done_ratio" => "90",
          "estimated_hours_touched" => "false",
          "remaining_hours_touched" => "false",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "assigns work package updated with touched and derived values" do
      params["work_package"]["estimated_hours"] = "50h"
      params["work_package"]["estimated_hours_touched"] = "true"

      get("edit", params:)

      assigned_work_package = assigns(:work_package)
      expect(assigned_work_package.estimated_hours).to eq(50)
      expect(assigned_work_package.remaining_hours).to eq(50) # derived
      expect(assigned_work_package.done_ratio).to eq(0) # derived
      expect(progress_errors(assigned_work_package)).to be_empty
    end

    context "when the user edits fields and does not have 'Add work packages' permission" do
      before do
        RolePermission.where(permission: "add_work_packages").delete_all
      end

      it "does not display any errors" do
        params["work_package"]["estimated_hours"] = "50h"
        params["work_package"]["estimated_hours_touched"] = "true"

        get("edit", params:)

        assigned_work_package = assigns(:work_package)
        expect(progress_errors(assigned_work_package)).to be_empty
      end
    end

    context "when the user edits fields and does not have 'Edit work packages' permission" do
      before do
        RolePermission.where(permission: "edit_work_packages").delete_all
      end

      it "display read-only errors" do
        params["work_package"]["estimated_hours"] = "50h"
        params["work_package"]["estimated_hours_touched"] = "true"

        get("edit", params:)

        assigned_work_package = assigns(:work_package)
        expect(progress_errors(assigned_work_package)).to match(
          estimated_hours: [have_attributes(class: ActiveModel::Error, type: :error_readonly)]
        )
      end
    end
  end

  describe "POST /work_packages/:id/progress" do
    let(:params) do
      {
        "work_package_id" => work_package.id,
        "work_package" => {
          "estimated_hours" => "42",
          "remaining_hours" => "4h",
          "done_ratio" => "90",
          "estimated_hours_touched" => "false",
          "remaining_hours_touched" => "false",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "updates the work package progress values with touched values (none touched)" do
      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to be_nil
      expect(work_package.remaining_hours).to be_nil
      expect(work_package.done_ratio).to be_nil
    end

    it "updates the work package progress values with touched values (only work touched)" do
      params["work_package"]["estimated_hours_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to eq(42)
      # when not supplied by the user, the remaining work is set to the same
      # value as work
      expect(work_package.remaining_hours).to eq(42)
      expect(work_package.done_ratio).to eq(0)
    end

    it "updates the work package progress values with touched values (only done_ratio touched)" do
      params["work_package"]["done_ratio_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to be_nil
      expect(work_package.remaining_hours).to be_nil
      expect(work_package.done_ratio).to eq(90)
    end

    it "updates the work package progress values (work and remaining work)" do
      params["work_package"]["estimated_hours_touched"] = "true"
      params["work_package"]["remaining_hours_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to eq(42)
      expect(work_package.remaining_hours).to eq(4)
      expect(work_package.done_ratio).to eq(90)
    end

    context "when the user enters invalid values" do
      it "replies with a 422 status and displays an error message related to the erroneous field in the modal" do
        params["work_package"]["estimated_hours_touched"] = "true"
        params["work_package"]["estimated_hours"] = "-1"
        patch("update", params:, as: :turbo_stream)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to have_turbo_stream action: "update"
        # the flash is not rendered with the progress field errors, as they are already in the progress modal
        expect(response).not_to have_turbo_stream action: "flash"
        template = Capybara.string(turbo_stream_template(action: "update"))
        expect(template).to have_css("primer-text-field:has(label:contains('Work')) .FormControl-inlineValidation",
                                     text: "Must be greater than or equal to 0.")
      end
    end

    context "when the work package cannot be saved due to other errors" do
      before do
        # update the work package in an invalid state
        work_package.update_column(:subject, "")
      end

      it "replies with a 422 status and displays an error message in a flash" do
        params["work_package"]["estimated_hours_touched"] = "true"
        params["work_package"]["estimated_hours"] = "0"
        patch("update", params:, as: :turbo_stream)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to have_turbo_stream action: "flash"
        expect(turbo_stream_template(action: "flash")).to include("Subject can't be blank.")
      end
    end
  end

  # Used on new work package creation form
  describe "POST /work_packages/progress" do
    let(:params) do
      {
        "work_package" => {
          "initial" => {
            "estimated_hours" => "",
            "remaining_hours" => "",
            "done_ratio" => ""
          },
          "estimated_hours" => "4h",
          "remaining_hours" => "3",
          "done_ratio" => "0",
          "estimated_hours_touched" => "true",
          "remaining_hours_touched" => "true",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "sends back the entered and derived progress values" do
      post("create", params:, as: :turbo_stream)

      expect(response.body).to be_json_eql({
        estimatedTime: "PT4H",
        remainingTime: "PT3H",
        percentageDone: 25
      }.to_json)
    end
  end
end
