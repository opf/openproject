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

require "rails_helper"

RSpec.describe WorkPackages::DatePicker::DateFormComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  create_shared_association_defaults_for_work_package_factory

  subject(:date_form) do
    with_controller_class(WorkPackages::DatePickerController) do
      with_request_url("/work_packages/date_picker") do
        render_inline(
          described_class.new(
            work_package:,
            schedule_manually:,
            disabled:,
            is_milestone:,
            focused_field:,
            triggering_field:,
            touched_field_map:,
            date_mode:
          )
        )
      end
    end
  end

  let(:work_package) { build(:work_package, start_date:, due_date:, duration:) }
  let(:start_date) { nil }
  let(:due_date) { nil }
  let(:duration) { nil }
  let(:schedule_manually) { true }
  let(:disabled) { false }
  let(:is_milestone) { false }
  let(:focused_field) { :due_date }
  let(:triggering_field) { nil }
  let(:touched_field_map) { {} }
  let(:date_mode) { nil }

  def expect_fields_shown(*names)
    names.each do |name|
      expect(date_form).to have_no_css(
        ".wp-datepicker-dialog-date-form--#{name.to_s.dasherize} " \
        ".wp-datepicker-dialog-date-form--button-container_visible"
      )
    end
  end

  def expect_fields_hidden(*names)
    names.each do |name|
      expect(date_form).to have_css(
        ".wp-datepicker-dialog-date-form--#{name.to_s.dasherize} " \
        ".wp-datepicker-dialog-date-form--button-container_visible"
      )
    end
  end

  def expect_focused(name)
    expect(date_form).to have_css(
      "#work_package_#{name}.op-datepicker-modal--date-field_current[data-focus='true'][data-qa-highlighted='true']"
    )
  end

  context "in single-date mode" do
    it "shows and focuses the due date when all values are empty" do
      expect_fields_hidden(:start_date)
      expect_fields_shown(:due_date)
      expect_focused(:due_date)
    end

    context "when opened through the combined date field" do
      let(:focused_field) { :combined_date }

      it "focuses the visible due date" do
        expect_focused(:due_date)
      end
    end

    context "with only a start date" do
      let(:start_date) { Date.new(2026, 8, 31) }

      it "shows and focuses the start date" do
        expect_fields_shown(:start_date)
        expect_fields_hidden(:due_date)
        expect_focused(:start_date)
      end
    end

    context "with only a due date" do
      let(:due_date) { Date.new(2026, 8, 31) }

      it "shows and focuses the due date" do
        expect_fields_hidden(:start_date)
        expect_fields_shown(:due_date)
        expect_focused(:due_date)
      end
    end

    context "with both dates" do
      let(:start_date) { Date.new(2026, 8, 30) }
      let(:due_date) { Date.new(2026, 8, 31) }

      it "shows both fields" do
        expect_fields_shown(:start_date, :due_date)
      end
    end

    context "with only a duration" do
      let(:duration) { 5 }

      it "keeps the due date field visible and renders the duration" do
        expect_fields_hidden(:start_date)
        expect_fields_shown(:due_date)
        expect(date_form).to have_field(WorkPackage.human_attribute_name("duration"), with: "5")
      end
    end

    context "when the empty start date was touched" do
      let(:touched_field_map) { { "start_date_touched" => true } }

      it "keeps the start date visible and the due date hidden" do
        expect_fields_shown(:start_date)
        expect_fields_hidden(:due_date)
        expect_focused(:start_date)
      end
    end

    context "when opened from the start-date table cell" do
      let(:triggering_field) { "startDate" }
      let(:focused_field) { :start_date }

      it "shows only the triggering field" do
        expect_fields_shown(:start_date)
        expect_fields_hidden(:due_date)
        expect_focused(:start_date)
      end
    end
  end

  context "in range mode" do
    let(:date_mode) { "range" }
    let(:focused_field) { :duration }

    it "shows both dates and focuses the requested field" do
      expect_fields_shown(:start_date, :due_date)
      expect_focused(:duration)
    end
  end

  context "for a milestone" do
    let(:is_milestone) { true }
    let(:focused_field) { :start_date }

    it "renders only the milestone date" do
      expect(date_form).to have_field(I18n.t("attributes.date"))
      expect(date_form).to have_no_field(I18n.t("attributes.due_date"))
      expect(date_form).to have_no_field(WorkPackage.human_attribute_name("duration"))
    end
  end

  context "when automatically scheduled" do
    let(:schedule_manually) { false }
    let(:date_mode) { "range" }
    let(:focused_field) { :start_date }

    it "disables the start date and leaves the due date editable" do
      expect(date_form).to have_field(I18n.t("attributes.start_date"), disabled: true)
      expect(date_form).to have_field(I18n.t("attributes.due_date"), disabled: false)
      expect(date_form).to have_no_css("#work_package_start_date.#{described_class::FOCUSED_CLASS}")
    end
  end
end
