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

RSpec.describe WorkPackages::DatePickerController do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
  shared_let(:work_package) do
    create(:work_package,
           start_date: "2025-04-01",
           due_date: "2025-04-07",
           duration: 5)
  end
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             work_package.project => %i[add_work_packages edit_work_packages view_work_packages]
           })
  end

  current_user { user }

  def date_errors(work_package)
    work_package.errors.group_by_attribute.slice(:start_date, :due_date, :duration)
  end

  # the parameters used to re-render the date picker after changing values is
  # enriched by the stimulus preview controller. Here nothing is changed yet,
  # each test uses this as a basis to update the values.
  # captured on 2025-04-17.
  let(:params_after_changing_values) do
    {
      "field" => "work_package[due_date]",
      "date_mode" => "single",
      "triggering_field" => "",
      "work_package" => {
        "start_date" => "",
        "due_date" => "2025-04-18",
        "duration" => "",
        "ignore_non_working_days" => "0",
        "schedule_manually" => "true",
        "initial" => {
          "start_date" => "",
          "due_date" => "2025-04-18",
          "duration" => "",
          "ignore_non_working_days" => "false",
          "schedule_manually" => "true"
        },
        "start_date_touched" => "false",
        "due_date_touched" => "false",
        "duration_touched" => "false",
        "ignore_non_working_days_touched" => "false",
        "schedule_manually_touched" => "false"
      }
    }
  end

  describe "GET /work_packages/date_picker/new" do
    # the parameters as they are sent when the date picker is opened again
    # from the new work package page after a due date has been entered.
    let(:params_from_first_display_of_date_picker) do
      {
        "field" => "combinedDate",
        "work_package" => {
          "start_date" => "",
          "due_date" => "2025-04-18",
          "duration" => "",
          "ignore_non_working_days" => "false",
          "initial" => {
            "start_date" => "",
            "due_date" => "2025-04-18",
            "duration" => "",
            "ignore_non_working_days" => "false"
          }
        }
      }
    end

    let(:params) { params_from_first_display_of_date_picker }

    subject { get("new", params:) }

    it "assigns work package initialized with initial values" do
      subject

      assigned_work_package = assigns(:work_package)
      expect(assigned_work_package).to be_new_record
      expect(assigned_work_package.start_date).to be_nil
      expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-18"))
      expect(assigned_work_package.duration).to be_nil
      expect(assigned_work_package.ignore_non_working_days).to be(false)
      expect(assigned_work_package.schedule_manually).to be(true) # the default value
      expect(date_errors(assigned_work_package)).to be_empty
    end

    context "when values for untouched fields are received (like derived values)" do
      let(:params) do
        params_after_changing_values.deep_merge(
          "work_package" => {
            "start_date" => "2025-01-01",
            "start_date_touched" => "false",
            "due_date" => "2025-04-21",
            "due_date_touched" => "false"
          }
        )
      end

      render_views

      it "keeps the initial value for untouched fields in the assigned work package" do
        subject

        assigned_work_package = assigns(:work_package)
        # initial values are used for untouched fields
        expect(assigned_work_package.start_date).to be_nil
        expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-18"))
      end

      it "does not include the live region turbo-stream" do
        subject

        expect(response.body).not_to include('<turbo-stream action="liveRegion"')
      end
    end
  end

  describe "GET /work_packages/date_picker/preview" do
    subject { get("preview", params:) }

    context "when values for untouched fields are received (like derived values)" do
      let(:params) do
        params_after_changing_values.deep_merge(
          "work_package" => {
            "start_date" => "2025-01-01",
            "start_date_touched" => "false",
            "due_date" => "2025-04-21",
            "due_date_touched" => "false"
          }
        )
      end

      it "keeps the initial value for untouched fields in the assigned work package" do
        subject
        assigned_work_package = assigns(:work_package)
        # initial values are used for untouched fields
        expect(assigned_work_package.start_date).to be_nil
        expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-18"))
      end
    end

    context "when the user edits the dates" do
      let(:params) do
        params_after_changing_values.deep_merge(
          "work_package" => {
            "start_date" => "2025-04-14",
            "start_date_touched" => "true",
            "due_date" => "2025-04-21",
            "due_date_touched" => "true"
          }
        )
      end

      it "assigns work package updated with touched and derived values" do
        subject

        assigned_work_package = assigns(:work_package)
        expect(assigned_work_package).to be_new_record
        expect(assigned_work_package.start_date).to eq(Date.parse("2025-04-14"))
        expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-21"))
        expect(assigned_work_package.duration).to eq(6)
        expect(date_errors(assigned_work_package)).to be_empty
      end

      context "when the user does not have 'Add work packages' permission" do
        before do
          RolePermission.where(permission: "add_work_packages").delete_all
        end

        it "displays read-only errors" do
          subject

          assigned_work_package = assigns(:work_package)
          expect(date_errors(assigned_work_package)).to match(
            start_date: [have_attributes(class: ActiveModel::Error, type: :error_readonly)],
            due_date: [have_attributes(class: ActiveModel::Error, type: :error_readonly)]
          )
        end
      end

      context "when the user edits fields and does not have 'Edit work packages' permission" do
        before do
          RolePermission.where(permission: "edit_work_packages").delete_all
        end

        it "does not display any errors" do
          subject

          assigned_work_package = assigns(:work_package)
          expect(date_errors(assigned_work_package)).to be_empty
        end
      end
    end

    context "when changing the start date" do
      let(:params) do
        params_after_changing_values.deep_merge(
          "work_package" => {
            "start_date" => "2025-04-15",
            "start_date_touched" => "true",
            "due_date" => "2025-04-21",
            "due_date_touched" => "true"
          }
        )
      end

      render_views

      it "includes the live region turbo-stream with the correct message and attributes" do
        subject

        expect(response.body).to include('<turbo-stream action="liveRegion"')
        expect(response.body).to include('politeness="polite"')
        expect(response.body).to include('delay="500"')

        expected_message = "Date picker updated. Scheduling mode: Manual, working days only, " +
          "Start date: 2025-04-15, Finish date: 2025-04-21, Duration: 5 days"
        expect(response.body).to include("message=\"#{expected_message}\"")
      end
    end
  end

  describe "GET /work_packages/:id/date_picker/preview" do
    context "when the work package is an automatically scheduled parent with dates inherited from child" do
      shared_let(:child) do
        create(:work_package,
               parent: work_package,
               subject: "child",
               start_date: work_package.start_date,
               due_date: work_package.due_date,
               duration: work_package.duration)
      end

      before do
        work_package.update(schedule_manually: false)
      end

      context "when the user clears the duration" do
        let(:params) do
          {
            "field" => "work_package[duration]",
            "date_mode" => "range",
            "triggering_field" => "combined_date",
            "work_package" => {
              "start_date" => "2025-04-01",
              "due_date" => "2025-04-07",
              "duration" => "", # <= here is the change: clear the duration
              "ignore_non_working_days" => "0",
              "schedule_manually" => "false",
              "initial" => {
                "start_date" => "2025-04-01",
                "due_date" => "2025-04-07",
                "duration" => "5",
                "ignore_non_working_days" => "false",
                "schedule_manually" => "false"
              },
              "start_date_touched" => "false",
              "due_date_touched" => "false",
              "duration_touched" => "true", # <= here is the change: clear the duration
              "ignore_non_working_days_touched" => "false",
              "schedule_manually_touched" => "false"
            }
          }
        end

        it "keeps the dates and duration from the child (Bug #68402)" do
          get("preview", params: params.merge("work_package_id" => work_package.id))

          expect(assigns(:work_package)).to have_attributes(
            start_date: child.start_date,
            due_date: child.due_date,
            duration: child.duration
          )
        end
      end
    end
  end

  describe "GET /work_packages/:id/progress" do
    let(:params_from_first_display_of_date_picker) do
      {
        "field" => "combinedDate",
        "work_package_id" => work_package.id,
        "work_package" => {
          "start_date" => "2025-04-01",
          "due_date" => "2025-04-07",
          "duration" => "P5D",
          "ignore_non_working_days" => "",
          "initial" => {
            "start_date" => "2025-04-01",
            "due_date" => "2025-04-07",
            "duration" => "P5D",
            "ignore_non_working_days" => ""
          }
        }
      }
    end
    let(:params_after_changing_values) do
      {
        "field" => "work_package[due_date]",
        "date_mode" => "range",
        "triggering_field" => "combined_date",
        "work_package_id" => work_package.id,
        "work_package" => {
          "start_date" => "2025-04-01",
          "due_date" => "2025-04-17",
          "duration" => "5",
          "ignore_non_working_days" => "0",
          "schedule_manually" => "true",
          "initial" => {
            "start_date" => "2025-04-01",
            "due_date" => "2025-04-07",
            "duration" => "5",
            "ignore_non_working_days" => "false",
            "schedule_manually" => "true"
          },
          "start_date_touched" => "false",
          "due_date_touched" => "true",
          "duration_touched" => "false",
          "ignore_non_working_days_touched" => "false",
          "schedule_manually_touched" => "false"
        }
      }
    end

    it "assigns work package initialized with initial values" do
      get("edit", params: params_from_first_display_of_date_picker)

      assigned_work_package = assigns(:work_package)
      expect(assigned_work_package).to be_persisted
      expect(assigned_work_package.start_date).to eq(Date.parse("2025-04-01"))
      expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-07"))
      expect(assigned_work_package.duration).to eq(5)
      expect(assigned_work_package.ignore_non_working_days).to be(false)
      expect(assigned_work_package.schedule_manually).to be(true) # default value
      expect(date_errors(assigned_work_package)).to be_empty
    end

    context "when the user edits the dates" do
      let(:params_after_editing_due_date) do
        params_after_changing_values.deep_merge(
          "work_package" => {
            "start_date" => "2025-04-03",
            "start_date_touched" => "true",
            "due_date" => "2025-04-15",
            "due_date_touched" => "true",
            "duration" => "3" # it was 3 before changing due date; will be derived (because not touched)
          }
        )
      end

      it "assigns work package updated with touched and derived values" do
        get("edit", params: params_after_editing_due_date)

        assigned_work_package = assigns(:work_package)
        expect(assigned_work_package).to be_persisted
        expect(assigned_work_package.start_date).to eq(Date.parse("2025-04-03"))
        expect(assigned_work_package.due_date).to eq(Date.parse("2025-04-15"))
        expect(assigned_work_package.duration).to eq(9)
        expect(date_errors(assigned_work_package)).to be_empty
      end

      context "when the user does not have 'Add work packages' permission" do
        before do
          RolePermission.where(permission: "add_work_packages").delete_all
        end

        it "does not display any errors" do
          get("edit", params: params_after_editing_due_date)

          assigned_work_package = assigns(:work_package)
          expect(date_errors(assigned_work_package)).to be_empty
        end
      end

      context "when the user does not have 'Edit work packages' permission" do
        before do
          RolePermission.where(permission: "edit_work_packages").delete_all
        end

        it "display read-only errors" do
          get("edit", params: params_after_editing_due_date)

          assigned_work_package = assigns(:work_package)
          expect(date_errors(assigned_work_package)).to match(
            start_date: [have_attributes(class: ActiveModel::Error, type: :error_readonly)],
            due_date: [have_attributes(class: ActiveModel::Error, type: :error_readonly)]
          )
        end
      end
    end
  end

  describe "PATCH /work_packages/:id/date_picker" do
    context "when changing a milestone successor scheduling mode from manual to automatic" do
      shared_let(:predecessor) do
        create(:work_package, schedule_manually: true,
                              start_date: "2025-06-10",
                              due_date: "2025-06-12",
                              duration: 3)
      end
      shared_let(:milestone_successor) do
        create(:work_package, :is_milestone, schedule_manually: true,
                                             start_date: "2025-06-16",
                                             due_date: "2025-06-16",
                                             duration: 1) do |successor|
          create(:follows_relation, predecessor:, successor:)
        end
      end

      let(:params) do
        {
          "work_package_id" => milestone_successor.id,
          "work_package" => {
            "ignore_non_working_days" => "0",
            "schedule_manually" => "false",
            "initial" => {
              "start_date" => "2025-06-16",
              "ignore_non_working_days" => "false",
              "schedule_manually" => "true"
            },
            "start_date_touched" => "false",
            "ignore_non_working_days_touched" => "false",
            "schedule_manually_touched" => "false"
          }
        }
      end

      it "updates the date to start as soon as possible (Bug #64603)" do
        patch("update", params:, format: :turbo_stream)
        expect(response).to have_http_status(:success)

        expect(milestone_successor.reload).to have_attributes(
          start_date: Date.parse("2025-06-13"),
          due_date: Date.parse("2025-06-13"),
          duration: 1
        )
      end
    end
  end
end
