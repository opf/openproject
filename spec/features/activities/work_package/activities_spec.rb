#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Work package activity", :js, :with_cuprite do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:member_role) do
    create(:project_role,
           permissions: %i[view_work_packages edit_work_packages add_work_packages work_package_assigned])
  end
  let(:member) do
    create(:user,
           firstname: "A",
           lastname: "Member",
           member_with_roles: { project => member_role })
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  context "when a workpackage is created and visited by the same user" do
    current_user { admin }
    let(:work_package) { create(:work_package, project:, author: admin) }

    before do
      # for some reason the journal is set to the "Anonymous"
      # although the work_package is created by the admin
      # so we need to update the journal to the admin manually to simulate the real world case
      work_package.journals.first.update!(user: admin)

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "shows and merges activities and comments correctly", :aggregate_failures do
      first_journal = work_package.journals.first

      # initial journal entry is shown without changeset or comment
      activity_tab.within_journal_entry(first_journal) do
        activity_tab.expect_journal_details_header(text: "created")
        activity_tab.expect_journal_details_header(text: admin.name)
        activity_tab.expect_no_journal_notes
        activity_tab.expect_no_journal_changed_attribute
      end

      wp_page.update_attributes(subject: "A new subject") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      # even when attributes are changed, the initial journal entry is still not showing any changeset
      activity_tab.within_journal_entry(first_journal) do
        activity_tab.expect_no_journal_changed_attribute
      end

      # merges the initial journal entry with the first comment when a comment is added right after the work package is created
      activity_tab.add_comment(text: "First comment")

      activity_tab.within_journal_entry(first_journal) do
        activity_tab.expect_no_journal_details_header
        activity_tab.expect_journal_notes_header(text: "created")
        activity_tab.expect_journal_notes_header(text: admin.name)
        activity_tab.expect_journal_notes(text: "First comment")
        activity_tab.expect_no_journal_changed_attribute
      end

      # changing the work package attributes after the first comment is added
      wp_page.update_attributes(subject: "A new subject!!!") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      # the changeset is still not shown in the journal entry
      activity_tab.within_journal_entry(first_journal) do
        activity_tab.expect_no_journal_changed_attribute
      end

      # adding a second comment
      activity_tab.add_comment(text: "Second comment")

      second_journal = work_package.journals.second

      activity_tab.within_journal_entry(second_journal) do
        activity_tab.expect_no_journal_changed_attribute
      end

      # changing the work package attributes after the first comment is added
      wp_page.update_attributes(subject: "A new subject") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      # the changeset is shown for the second journal entry (all but initial)
      activity_tab.within_journal_entry(second_journal) do
        activity_tab.expect_journal_changed_attribute(text: "Subject")
      end

      wp_page.update_attributes(assignee: member.name) # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      # the changeset is merged for the second journal entry
      activity_tab.within_journal_entry(second_journal) do
        activity_tab.expect_journal_changed_attribute(text: "Subject")
        activity_tab.expect_journal_changed_attribute(text: "Assignee")
      end
    end
  end

  context "when a workpackage is created and visited by different users" do
    current_user { member }
    let(:work_package) { create(:work_package, project:, author: admin) }

    before do
      # for some reason the journal is set to the "Anonymous"
      # although the work_package is created by the admin
      # so we need to update the journal to the admin manually to simulate the real world case
      work_package.journals.first.update!(user: admin)

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "shows and merges activities and comments correctly", :aggregate_failures do
      first_journal = work_package.journals.first

      # initial journal entry is shown without changeset or comment
      activity_tab.within_journal_entry(first_journal) do
        activity_tab.expect_journal_details_header(text: "created")
        activity_tab.expect_journal_details_header(text: admin.name)
        activity_tab.expect_no_journal_notes
        activity_tab.expect_no_journal_changed_attribute
      end

      wp_page.update_attributes(subject: "A new subject") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      second_journal = work_package.journals.second
      # even when attributes are changed, the initial journal entry is still not showing any changeset
      activity_tab.within_journal_entry(second_journal) do
        activity_tab.expect_journal_details_header(text: "change")
        activity_tab.expect_journal_details_header(text: member.name)
        activity_tab.expect_journal_changed_attribute(text: "Subject")
      end

      # merges the second journal entry with the comment made by the user right afterwards
      activity_tab.add_comment(text: "First comment")

      activity_tab.within_journal_entry(second_journal) do
        activity_tab.expect_no_journal_details_header
        activity_tab.expect_journal_notes_header(text: "commented")
        activity_tab.expect_journal_notes_header(text: member.name)
        activity_tab.expect_journal_notes(text: "First comment")
      end

      travel_to 1.hour.from_now

      # the journals will not be merged due to the time difference

      wp_page.update_attributes(subject: "A new subject!!!") # rubocop:disable Rails/ActiveRecordAliases

      third_journal = work_package.journals.third

      activity_tab.within_journal_entry(third_journal) do
        activity_tab.expect_journal_details_header(text: "change")
        activity_tab.expect_journal_details_header(text: member.name)
        activity_tab.expect_journal_changed_attribute(text: "Subject")
      end
    end
  end

  context "when multiple users are commenting on a workpackage" do
    current_user { admin }
    let(:work_package) { create(:work_package, project:, author: admin) }

    before do
      # set WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS to 1000
      # to speed up the polling interval for test duration
      ENV["WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS"] = "1000"

      # for some reason the journal is set to the "Anonymous"
      # although the work_package is created by the admin
      # so we need to update the journal to the admin manually to simulate the real world case
      work_package.journals.first.update!(user: admin)

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    after do
      ENV.delete("WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS")
    end

    it "shows the comment of another user without browser reload", :aggregate_failures do
      # simulate member creating a comment
      sleep 1 # the comment needs to be created after the component is mounted
      first_journal = create(:work_package_journal, user: member, notes: "First comment by member", journable: work_package,
                                                    version: 2)

      # the comment is shown without browser reload
      activity_tab.expect_journal_notes(text: "First comment by member")

      # simulate comments made within the polling interval
      create(:work_package_journal, user: member, notes: "Second comment by member", journable: work_package, version: 3)
      create(:work_package_journal, user: member, notes: "Third comment by member", journable: work_package, version: 4)

      activity_tab.add_comment(text: "First comment by admin")

      expect(activity_tab.get_all_comments_as_arrary).to eq([
                                                              "First comment by member",
                                                              "Second comment by member",
                                                              "Third comment by member",
                                                              "First comment by admin"
                                                            ])

      first_journal.update!(notes: "First comment by member updated")

      # properly updates the comment when the comment is updated
      activity_tab.expect_journal_notes(text: "First comment by member updated")
    end
  end

  describe "filtering" do
    current_user { admin }
    let(:work_package) { create(:work_package, project:, author: admin) }

    before do
      # for some reason the journal is set to the "Anonymous"
      # although the work_package is created by the admin
      # so we need to update the journal to the admin manually to simulate the real world case
      work_package.journals.first.update!(user: admin)

      create(:work_package_journal, user: admin, notes: "First comment by admin", journable: work_package, version: 2)
      create(:work_package_journal, user: admin, notes: "Second comment by admin", journable: work_package, version: 3)

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "filters the activities based on type", :aggregate_failures do
      # add a non-comment journal entry by changing the work package attributes
      wp_page.update_attributes(subject: "A new subject") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      # expect all journal entries
      activity_tab.expect_journal_notes(text: "First comment by admin")
      activity_tab.expect_journal_notes(text: "Second comment by admin")
      activity_tab.expect_journal_changed_attribute(text: "Subject")

      activity_tab.filter_journals(:only_comments)

      # expect only the comments
      activity_tab.expect_journal_notes(text: "First comment by admin")
      activity_tab.expect_journal_notes(text: "Second comment by admin")
      activity_tab.expect_no_journal_changed_attribute(text: "Subject")

      activity_tab.filter_journals(:only_changes)

      # expect only the changes
      activity_tab.expect_no_journal_notes(text: "First comment by admin")
      activity_tab.expect_no_journal_notes(text: "Second comment by admin")
      activity_tab.expect_journal_changed_attribute(text: "Subject")

      activity_tab.filter_journals(:all)

      # expect all journal entries
      activity_tab.expect_journal_notes(text: "First comment by admin")
      activity_tab.expect_journal_notes(text: "Second comment by admin")
      activity_tab.expect_journal_changed_attribute(text: "Subject")

      # strip journal entries with comments and changesets down to the comments

      # creating a journal entry with both a comment and a changeset
      activity_tab.add_comment(text: "Third comment by admin")
      wp_page.update_attributes(subject: "A new subject!!!") # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      latest_journal = work_package.journals.last

      activity_tab.within_journal_entry(latest_journal) do
        activity_tab.expect_journal_notes_header(text: "commented")
        activity_tab.expect_journal_notes_header(text: admin.name)
        activity_tab.expect_journal_notes(text: "Third comment by admin")
        activity_tab.expect_journal_changed_attribute(text: "Subject")
        activity_tab.expect_no_journal_details_header
      end

      activity_tab.filter_journals(:only_comments)

      activity_tab.within_journal_entry(latest_journal) do
        activity_tab.expect_journal_notes_header(text: "commented")
        activity_tab.expect_journal_notes_header(text: admin.name)
        activity_tab.expect_journal_notes(text: "Third comment by admin")
        activity_tab.expect_no_journal_changed_attribute
        activity_tab.expect_no_journal_details_header
      end

      activity_tab.filter_journals(:only_changes)

      activity_tab.within_journal_entry(latest_journal) do
        activity_tab.expect_no_journal_notes_header
        activity_tab.expect_no_journal_notes
        activity_tab.expect_journal_details_header(text: "change")
        activity_tab.expect_journal_details_header(text: admin.name)
        activity_tab.expect_journal_changed_attribute(text: "Subject")
      end
    end
  end

  describe "sorting" do
    current_user { admin }
    let(:work_package) { create(:work_package, project:, author: admin) }

    before do
      # for some reason the journal is set to the "Anonymous"
      # although the work_package is created by the admin
      # so we need to update the journal to the admin manually to simulate the real world case
      work_package.journals.first.update!(user: admin)

      create(:work_package_journal, user: admin, notes: "First comment by admin", journable: work_package, version: 2)
      create(:work_package_journal, user: admin, notes: "Second comment by admin", journable: work_package, version: 3)

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "sorts the activities based on the sorting preference", :aggregate_failures do
      # expect the default sorting to be asc
      expect(activity_tab.get_all_comments_as_arrary).to eq([
                                                              "First comment by admin",
                                                              "Second comment by admin"
                                                            ])
      activity_tab.set_journal_sorting(:desc)

      expect(activity_tab.get_all_comments_as_arrary).to eq([
                                                              "Second comment by admin",
                                                              "First comment by admin"
                                                            ])

      activity_tab.set_journal_sorting(:asc)

      expect(activity_tab.get_all_comments_as_arrary).to eq([
                                                              "First comment by admin",
                                                              "Second comment by admin"
                                                            ])
    end
  end
end
