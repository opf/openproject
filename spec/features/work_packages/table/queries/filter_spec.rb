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

RSpec.describe "filter work packages", :js do
  shared_let(:user) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:watcher) { create(:user) }
  shared_let(:role) { create(:existing_project_role, permissions: [:view_work_packages]) }
  shared_let(:project) { create(:project, members: { watcher => role }) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  current_user { user }

  context "by watchers" do
    let(:work_package_with_watcher) do
      wp = build(:work_package, project:)
      wp.add_watcher watcher
      wp.save!

      wp
    end
    let(:work_package_without_watcher) { create(:work_package, project:) }

    before do
      work_package_with_watcher
      work_package_without_watcher

      wp_table.visit!
    end

    # Regression test for bug #24114 (broken watcher filter)
    it "onlies filter work packages by watcher" do
      filters.open
      loading_indicator_saveguard

      filters.add_filter_by "Watcher", "is (OR)", watcher.name
      loading_indicator_saveguard

      wp_table.expect_work_package_listed work_package_with_watcher
      wp_table.ensure_work_package_not_listed! work_package_without_watcher
    end
  end

  context "by version in project" do
    let(:version) { create(:version, project:) }
    let(:work_package_with_version) do
      create(:work_package, project:, subject: "With version", version:)
    end
    let(:work_package_without_version) { create(:work_package, subject: "Without version", project:) }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it "allows filtering, saving, retrieving and altering the saved filter" do
      filters.open

      filters.add_filter_by("Version", "is (OR)", version.name)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      wp_table.save_as("Some query name")

      filters.remove_filter "version"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      filters.open

      filters.expect_filter_by("Version", "is (OR)", version.name)

      filters.set_operator "Version", "is not"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_without_version
      wp_table.ensure_work_package_not_listed! work_package_with_version
    end
  end

  context "when filtering by status in project" do
    let(:status) { create(:status, name: "Open status") }
    let(:closed_status) { create(:closed_status, name: "Closed status") }
    let(:work_package_with_status) do
      create(:work_package, project:, subject: "With open status", status:)
    end
    let(:work_package_without_status) { create(:work_package, subject: "With closed status", project:, status: closed_status) }

    before do
      work_package_with_status
      work_package_without_status

      wp_table.visit!
    end

    it "allows filtering and matching the selected value" do
      filters.open

      filters.remove_filter :status
      filters.expect_no_filter_by :status
      filters.add_filter_by("Status", "is (OR)", status.name)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_status
      wp_table.ensure_work_package_not_listed! work_package_without_status

      filters.open_autocompleter :status

      expect(page).to have_css(".ng-option", text: closed_status.name)
      expect(page).to have_no_css(".ng-option", text: status.name)
    end
  end

  context "by finish date outside of a project" do
    let(:work_package_with_due_date) { create(:work_package, project:, due_date: Date.current) }
    let(:work_package_without_due_date) { create(:work_package, project:, due_date: 5.days.from_now) }
    let(:wp_table) { Pages::WorkPackagesTable.new }

    before do
      work_package_with_due_date
      work_package_without_due_date

      wp_table.visit!
    end

    it "allows filtering, saving and retrieving and altering the saved filter" do
      filters.open

      filters.add_filter_by("Finish date",
                            "between",
                            [1.day.ago.strftime("%Y-%m-%d"), Date.current.strftime("%Y-%m-%d")],
                            "dueDate")

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_due_date
      wp_table.ensure_work_package_not_listed! work_package_without_due_date

      wp_table.save_as("Some query name")

      filters.remove_filter "dueDate"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_due_date, work_package_without_due_date

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_due_date
      wp_table.ensure_work_package_not_listed! work_package_without_due_date

      filters.open

      filters.expect_filter_by("Finish date",
                               "between",
                               [1.day.ago.strftime("%Y-%m-%d"), Date.current.strftime("%Y-%m-%d")],
                               "dueDate")

      filters.set_filter "Finish date", "in more than", "1", "dueDate"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_without_due_date
      wp_table.ensure_work_package_not_listed! work_package_with_due_date
    end
  end

  context "by list cf inside a project" do
    let(:type) do
      type = create(:type)

      project.types << type

      type
    end

    let(:work_package_with_list_value) do
      wp = create(:work_package, project:, type:)
      wp.send(list_cf.attribute_setter, list_cf.custom_options.first.id)
      wp.save!
      wp
    end

    let(:work_package_with_anti_list_value) do
      wp = create(:work_package, project:, type:)
      wp.send(list_cf.attribute_setter, list_cf.custom_options.last.id)
      wp.save!
      wp
    end

    let(:list_cf) do
      cf = create(:list_wp_custom_field)

      project.work_package_custom_fields << cf
      type.custom_fields << cf

      cf
    end

    before do
      list_cf
      work_package_with_list_value
      work_package_with_anti_list_value

      wp_table.visit!
    end

    it "allows filtering, saving and retrieving the saved filter" do
      # Wait for form to load
      filters.expect_loaded

      filters.open
      filters.add_filter_by(list_cf.name,
                            "is not",
                            list_cf.custom_options.last.value,
                            list_cf.attribute_name(:camel_case))

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_list_value
      wp_table.ensure_work_package_not_listed! work_package_with_anti_list_value

      # Do not display already selected values in the autocompleter (Regression #46249)
      filters.open_autocompleter list_cf.attribute_name(:camel_case)

      expect(page).to have_no_css(".ng-option", text: list_cf.custom_options.last.value)

      wp_table.save_as("Some query name")

      filters.remove_filter list_cf.attribute_name(:camel_case)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_list_value, work_package_with_anti_list_value

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_list_value
      wp_table.ensure_work_package_not_listed! work_package_with_anti_list_value

      filters.open

      filters.expect_filter_by(list_cf.name,
                               "is not",
                               list_cf.custom_options.last.value,
                               "customField#{list_cf.id}")
    end
  end

  context "by string cf inside a project with url-query relevant chars" do
    let(:type) do
      type = create(:type)

      project.types << type

      type
    end

    let(:work_package_plus) do
      wp = create(:work_package, project:, type:)
      wp.send(string_cf.attribute_setter, "G+H")
      wp.save!
      wp
    end

    let(:work_package_and) do
      wp = create(:work_package, project:, type:)
      wp.send(string_cf.attribute_setter, "A&B")
      wp.save!
      wp
    end

    let(:string_cf) do
      cf = create(:string_wp_custom_field)

      project.work_package_custom_fields << cf
      type.custom_fields << cf

      cf
    end

    before do
      string_cf
      work_package_plus
      work_package_and

      wp_table.visit!
    end

    it "allows filtering, saving and retrieving the saved filter" do
      # Wait for form to load
      filters.expect_loaded

      filters.open
      filters.add_filter_by(string_cf.name,
                            "is",
                            ["G+H"],
                            string_cf.attribute_name(:camel_case))

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_plus
      wp_table.ensure_work_package_not_listed! work_package_and

      wp_table.save_as("Some query name")

      filters.remove_filter string_cf.attribute_name(:camel_case)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_plus, work_package_and

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_plus
      wp_table.ensure_work_package_not_listed! work_package_and

      filters.open

      filters.expect_filter_by(string_cf.name,
                               "is",
                               ["G+H"],
                               "customField#{string_cf.id}")

      filters.set_filter(string_cf,
                         "is",
                         ["A&B"],
                         string_cf.attribute_name(:camel_case))

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_and
      wp_table.ensure_work_package_not_listed! work_package_plus
    end
  end

  context "by attachment content" do
    let(:attachment_a) { build(:attachment, filename: "attachment-first.pdf") }
    let(:attachment_b) { build(:attachment, filename: "attachment-second.pdf") }
    let(:wp_with_attachment_a) do
      create(:work_package, subject: "WP attachment A", project:, attachments: [attachment_a])
    end
    let(:wp_with_attachment_b) do
      create(:work_package, subject: "WP attachment B", project:, attachments: [attachment_b])
    end
    let(:wp_without_attachment) { create(:work_package, subject: "WP no attachment", project:) }
    let(:wp_table) { Pages::WorkPackagesTable.new }

    before do
      allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_return("I am the first text $1.99.")
      wp_with_attachment_a
      Attachments::ExtractFulltextJob.perform_now(attachment_a.id)
      allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_return("I am the second text.")
      wp_with_attachment_b
      Attachments::ExtractFulltextJob.perform_now(attachment_b.id)
      wp_without_attachment
    end

    context "with full text search capabilities" do
      before do
        skip("Database does not support full text search.") unless OpenProject::Database::allows_tsv?
      end

      it "allows filtering and retrieving and altering the saved filter" do
        wp_table.visit!
        wp_table.expect_work_package_listed wp_with_attachment_a, wp_with_attachment_b

        filters.open

        # content contains with multiple hits
        filters.add_filter_by("Attachment content",
                              "contains",
                              ["text"],
                              "attachmentContent")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_a, wp_with_attachment_b
        wp_table.ensure_work_package_not_listed! wp_without_attachment

        # content contains single hit with numbers
        filters.remove_filter "attachmentContent"

        filters.add_filter_by("Attachment content",
                              "contains",
                              ["first 1.99"],
                              "attachmentContent")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_a
        wp_table.ensure_work_package_not_listed! wp_without_attachment, wp_with_attachment_b

        filters.remove_filter "attachmentContent"

        # content does not contain
        filters.add_filter_by("Attachment content",
                              "doesn't contain",
                              ["first"],
                              "attachmentContent")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_b, wp_without_attachment
        wp_table.ensure_work_package_not_listed! wp_with_attachment_a

        filters.remove_filter "attachmentContent"

        # ignores special characters
        filters.add_filter_by("Attachment content",
                              "contains",
                              ["! first:* ')"],
                              "attachmentContent")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_a
        wp_table.ensure_work_package_not_listed! wp_without_attachment, wp_with_attachment_b

        filters.remove_filter "attachmentContent"

        # file name contains
        filters.add_filter_by("Attachment file name",
                              "contains",
                              ["first"],
                              "attachmentFileName")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_a
        wp_table.ensure_work_package_not_listed! wp_without_attachment, wp_with_attachment_b

        filters.remove_filter "attachmentFileName"

        # file name does not contain
        filters.add_filter_by("Attachment file name",
                              "doesn't contain",
                              ["first"],
                              "attachmentFileName")

        loading_indicator_saveguard
        wp_table.expect_work_package_listed wp_with_attachment_b
        wp_table.ensure_work_package_not_listed! wp_with_attachment_a
      end
    end
  end

  context "DB does not offer TSVector support" do
    before do
      allow(OpenProject::Database).to receive(:allows_tsv?).and_return(false)
    end

    it "does not offer attachment filters" do
      expect(page).to have_no_select "add_filter_select", with_options: ["Attachment content", "Attachment file name"]
    end
  end

  describe "datetime filters" do
    shared_let(:wp_updated_today) do
      create(:work_package,
             subject: "Created today",
             project:,
             created_at: Time.current.change(hour: 12),
             updated_at: Time.current.change(hour: 12))
    end
    shared_let(:wp_updated_3d_ago) do
      create(:work_package,
             subject: "Created 3d ago",
             project:,
             created_at: 3.days.ago,
             updated_at: 3.days.ago)
    end
    shared_let(:wp_updated_5d_ago) do
      create(:work_package,
             subject: "Created 5d ago",
             project:,
             created_at: 5.days.ago,
             updated_at: 5.days.ago)
    end

    it "filters on date by created_at (Regression #28459)" do
      wp_table.visit!
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.open

      filters.add_filter_by "Created on",
                            "on",
                            [Date.current.iso8601],
                            "createdAt"

      loading_indicator_saveguard

      wp_table.expect_work_package_listed wp_updated_today
      wp_table.ensure_work_package_not_listed! wp_updated_3d_ago, wp_updated_5d_ago
    end

    it "filters on date by updated_at" do
      wp_table.visit!
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.open

      filters.add_filter_by "Updated",
                            "on",
                            [Date.current.iso8601],
                            "updatedAt"

      loading_indicator_saveguard

      wp_table.expect_work_package_listed wp_updated_today
      wp_table.ensure_work_package_not_listed! wp_updated_3d_ago, wp_updated_5d_ago
    end

    it "filters between date by updated_at", :with_cuprite do
      wp_table.visit!
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.open

      filters.add_filter_by "Updated",
                            "between",
                            [4.days.ago.to_date.iso8601, 2.days.ago.to_date.iso8601],
                            "updatedAt"

      wait_for_reload
      loading_indicator_saveguard

      wp_table.expect_work_package_listed wp_updated_3d_ago
      wp_table.ensure_work_package_not_listed! wp_updated_today, wp_updated_5d_ago

      wp_table.save_as("Some query name")

      filters.remove_filter "updatedAt"

      wait_for_reload
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      last_query = Query.where(name: "Some query name").first
      date_filter = last_query.filters.last

      # The frontend sends the date as a datetime string in utc where both bounds have the local offset deduced
      # e.g. ["2023-05-31T22:00:00Z", "2023-06-03T21:59:59Z"]
      Time.use_zone(ActiveSupport::TimeZone[Time.now.getlocal.zone]) do
        expect(date_filter.values)
          .to eq [(Time.now.getlocal - 4.days).beginning_of_day.utc.iso8601, (Time.now.getlocal - 2.days).end_of_day.utc.iso8601]
      end

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_3d_ago
      wp_table.ensure_work_package_not_listed! wp_updated_today, wp_updated_5d_ago

      filters.open

      filters.expect_filter_by "Updated on",
                               "between",
                               [4.days.ago.to_date.iso8601, 2.days.ago.to_date.iso8601],
                               "updatedAt"
    end

    it "filters between date by updated_at (lower boundary only)" do
      wp_table.visit!
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.open

      filters.add_filter_by "Updated",
                            "between",
                            [3.days.ago.to_date.iso8601],
                            "updatedAt"

      loading_indicator_saveguard

      wp_table.expect_work_package_listed wp_updated_3d_ago, wp_updated_today
      wp_table.ensure_work_package_not_listed! wp_updated_5d_ago

      wp_table.save_as("Some query name")

      filters.remove_filter "updatedAt"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_5d_ago

      filters.add_filter_by "Updated",
                            "between",
                            [6.days.ago.to_date.iso8601],
                            "updatedAt"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      last_query = Query.where(name: "Some query name").first
      date_filter = last_query.filters.last
      expect(date_filter.values)
        .to eq [3.days.ago.utc.beginning_of_day.iso8601]

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_3d_ago, wp_updated_today
      wp_table.ensure_work_package_not_listed! wp_updated_5d_ago

      filters.open

      filters.expect_filter_by "Updated on",
                               "between",
                               [3.days.ago.to_date.iso8601, ""],
                               "updatedAt"
    end

    it "filters between date by updated_at (upper boundary only)" do
      wp_table.visit!
      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.open

      filters.add_filter_by "Updated",
                            "between",
                            [nil, 4.days.ago.to_date.iso8601],
                            "updatedAt"

      loading_indicator_saveguard

      wp_table.expect_work_package_listed wp_updated_5d_ago
      wp_table.ensure_work_package_not_listed! wp_updated_3d_ago, wp_updated_today

      wp_table.save_as("Some query name")

      filters.remove_filter "updatedAt"

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_today, wp_updated_3d_ago, wp_updated_5d_ago

      filters.add_filter_by "Updated",
                            "between",
                            [nil, 6.days.ago.to_date.iso8601],
                            "updatedAt"

      loading_indicator_saveguard
      wp_table.ensure_work_package_not_listed! wp_updated_5d_ago, wp_updated_3d_ago, wp_updated_today

      last_query = Query.where(name: "Some query name").first
      date_filter = last_query.filters.last
      expect(date_filter.values)
        .to eq ["", 4.days.ago.utc.end_of_day.iso8601]

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed wp_updated_5d_ago
      wp_table.ensure_work_package_not_listed! wp_updated_3d_ago, wp_updated_today

      filters.open

      filters.expect_filter_by "Updated on",
                               "between",
                               ["", 4.days.ago.to_date.iso8601],
                               "updatedAt"
    end
  end

  describe "keep the filter attribute order (Regression #33136)" do
    let(:version1) { create(:version, project:, name: "Version 1", id: 1) }
    let(:version2) { create(:version, project:, name: "Version 2", id: 2) }

    it do
      wp_table.visit!
      loading_indicator_saveguard

      filters.open
      filters.add_filter_by "Version", "is (OR)", [version2.name, version1.name]
      loading_indicator_saveguard

      sleep(3)

      filters.expect_filter_by "Version", "is (OR)", [version1.name]
      filters.expect_filter_by "Version", "is (OR)", [version2.name]

      # Order should stay unchanged
      filters.expect_filter_order("Version", [version2.name, version1.name])
    end
  end

  describe "add parent WP filter" do
    let(:wp_parent) { create(:work_package, project:, subject: "project") }
    let(:wp_child1) { create(:work_package, project:, subject: "child 1", parent: wp_parent) }
    let(:wp_child2) { create(:work_package, project:, subject: "child 2", parent: wp_parent) }
    let(:wp_default) { create(:work_package, project:, subject: "default") }

    it do
      wp_parent
      wp_child1
      wp_child2
      wp_default
      wp_table.visit!
      loading_indicator_saveguard
      filters.expect_loaded
      filters.open
      filters.add_filter_by "Parent", "is (OR)", [wp_parent.subject]
      loading_indicator_saveguard

      # It should show the children of the selected parent
      wp_table.expect_work_package_listed wp_child1, wp_child2
      wp_table.ensure_work_package_not_listed! wp_default
    end
  end
end
