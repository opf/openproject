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
require "pdf/inspector"

RSpec.describe CostQuery::PDF::TimesheetGenerator do
  include Redmine::I18n
  let(:query) { create(:cost_query) }
  let(:user) { create(:user, firstname: "Export", lastname: "User") }
  let(:time_entry_user) { create(:user, firstname: "TimeEntry", lastname: "User") }
  let(:project) { create(:project) }
  let(:generator) { described_class.new(query, project) }
  let(:export_time) { DateTime.new(2024, 12, 4, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, include_date: true) }
  let(:export_date_formatted) { format_date(export_time) }
  let(:user_time_entry) do
    create(:time_entry,
           project:,
           user: user,
           spent_on: Date.new(2024, 12, 0o1),
           start_time: 8 * 60,
           hours: 28,
           time_zone: "UTC")
  end
  let(:time_entry) do
    create(:time_entry,
           project:,
           user: time_entry_user,
           spent_on: Date.new(2024, 12, 0o1),
           start_time: 9 * 60,
           time_zone: "UTC")
  end
  let(:other_time_entry) do
    create(:time_entry,
           project:,
           user: time_entry_user,
           spent_on: Date.new(2024, 12, 0o1),
           start_time: 10 * 60,
           time_zone: "UTC")
  end
  let(:time_entry_with_comment) do
    create(:time_entry,
           project:,
           user: time_entry_user,
           comments: "This is a comment",
           spent_on: Date.new(2024, 12, 0o2))
  end
  let(:time_entry_without_time) do
    create(:time_entry,
           project:,
           user: time_entry_user,
           spent_on: Date.new(2024, 12, 0o3))
  end
  let(:time_entries) { [user_time_entry, time_entry, other_time_entry, time_entry_with_comment, time_entry_without_time] }

  before do
    User.current = user
    allow(generator).to receive(:all_entries).and_return(time_entries)
  end

  subject(:pdf) do
    content = Timecop.freeze(export_time) do
      generator.generate!
    end
    # If you want to actually see the PDF for debugging, uncomment the following line
    # File.binwrite("TimesheetGenerator-test-preview.pdf", content)
    PDF::Inspector::Text.analyze(content).strings.join(" ")
  end

  def expected_cover_page
    ["OpenProject", query.name,
     time_entries.empty? ? nil : "#{format_date(time_entries.first.spent_on)} - #{format_date(time_entries.last.spent_on)}",
     user.name, export_time_formatted].compact
  end

  def expected_starting_content
    [query.name]
  end

  def expected_table_header(with_times_column)
    [
      I18n.t(:"activerecord.attributes.time_entry.spent_on"),
      I18n.t(:"activerecord.models.work_package"),
      with_times_column ? I18n.t(:"export.timesheet.time") : nil,
      I18n.t(:"activerecord.attributes.time_entry.hours"),
      I18n.t(:"activerecord.attributes.time_entry.activity")
    ].compact
  end

  def expected_page_footer(page_number)
    [page_number, export_date_formatted, query.name]
  end

  def expected_sum_row(row_user, _with_times_column)
    sum = time_entries.filter { |t_entry| t_entry.user == row_user }.sum(&:hours)
    [generator.format_hours(sum)]
  end

  def expected_entry_row(t_entry, with_times_column)
    result = [generator.format_date_with_weekday(t_entry.spent_on)]
    result.concat(expected_entry_columns(t_entry, with_times_column))
  end

  def expected_entry_columns(t_entry, with_times_column)
    time_column = generator.format_spent_on_time(t_entry)
    [
      "##{t_entry.entity.id} ",
      t_entry.entity&.subject || "",
      with_times_column && time_column.present? ? time_column : nil,
      generator.format_hours(t_entry.hours),
      t_entry.activity.name,
      t_entry.comments
    ].compact
  end

  def expected_overview_table_content
    [
      I18n.t("export.timesheet.overview_per_user_total"),
      TimeEntry.human_attribute_name(:user),
      I18n.t("export.timesheet.sums_hours"),
      user.name,
      generator.format_hours(time_entries.select { |entry| entry.user == user }.sum(&:hours)),
      time_entry_user.name,
      generator.format_hours(time_entries.select { |entry| entry.user == time_entry_user }.sum(&:hours)),
      generator.format_hours(time_entries.sum(&:hours))
    ]
  end

  def expected_overview_sums_content
    [
      I18n.t("export.timesheet.overview_per_user_day"),
      TimeEntry.human_attribute_name(:spent_on),
      user.name,
      time_entry_user.name,

      generator.format_date_with_weekday(user_time_entry.spent_on),
      generator.format_hours(user_time_entry.hours), generator.format_hours(time_entry.hours + other_time_entry.hours),

      generator.format_date_with_weekday(time_entry_with_comment.spent_on),
      generator.format_hours(time_entry_with_comment.hours),

      generator.format_date_with_weekday(time_entry_without_time.spent_on),
      generator.format_hours(time_entry_without_time.hours),

      I18n.t("export.timesheet.sums_hours"),
      generator.format_hours(time_entries.select { |entry| entry.user == user }.sum(&:hours)),
      generator.format_hours(time_entries.select { |entry| entry.user == time_entry_user }.sum(&:hours))
    ]
  end

  def expected_overview_page_content
    [query.name] + expected_overview_table_content + expected_overview_sums_content
  end

  def expected_first_user_table(with_times_column)
    [
      user.name,
      *expected_table_header(with_times_column),
      *expected_entry_row(user_time_entry, with_times_column)
    ]
  end

  def expected_second_user_table(with_times_column)
    [
      time_entry.user.name,
      *expected_table_header(with_times_column),
      generator.format_date_with_weekday(time_entry.spent_on), # merged date rows
      *expected_entry_columns(time_entry, with_times_column),
      *expected_entry_columns(other_time_entry, with_times_column),
      generator.format_hours(time_entry.hours + other_time_entry.hours),
      *expected_entry_row(time_entry_with_comment, with_times_column),
      *expected_entry_row(time_entry_without_time, with_times_column),
      *expected_sum_row(time_entry.user, with_times_column)
    ]
  end

  def expected_document(with_times_column)
    [
      *expected_cover_page,

      *expected_overview_page_content,
      *expected_page_footer("2/3"),

      *expected_starting_content,
      *expected_first_user_table(with_times_column),
      *expected_second_user_table(with_times_column),
      *expected_page_footer("3/3")
    ].join(" ")
  end

  context "with allow_tracking_start_and_end_times", with_settings: { allow_tracking_start_and_end_times: true } do
    it "renders the expected document" do
      expect(subject).to eq expected_document(true)
    end
  end

  context "without allow_tracking_start_and_end_times", with_settings: { allow_tracking_start_and_end_times: false } do
    it "renders the expected document" do
      expect(subject).to eq expected_document(false)
    end
  end

  context "with semantic work package identifiers",
          with_settings: { work_packages_identifier: "semantic", allow_tracking_start_and_end_times: false } do
    before do
      user_time_entry.entity.update_columns(identifier: "PROD-42", sequence_number: 42)
    end

    it "renders the semantic identifier in the work package column" do
      expect(subject).to include("PROD-42")
      expect(subject).not_to include("##{user_time_entry.entity.id}")
    end
  end
end
