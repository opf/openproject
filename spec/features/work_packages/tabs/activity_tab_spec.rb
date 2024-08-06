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

require "features/work_packages/work_packages_page"
require "support/edit_fields/edit_field"

RSpec.describe "Activity tab", :js, :with_cuprite do
  let(:project) do
    create(:project_with_types,
           types: [type_with_cf],
           work_package_custom_fields: [custom_field],
           public: true)
  end

  let(:custom_field) { create(:text_wp_custom_field) }

  let(:type_with_cf) do
    create(:type, custom_fields: [custom_field])
  end

  let(:creation_time) { 5.days.ago }
  let(:subject_change_time) { 3.days.ago }
  let(:revision_time) { 2.days.ago }
  let(:comment_time) { 1.day.ago }

  let!(:work_package) do
    create(:work_package,
           project:,
           created_at: creation_time,
           subject: initial_subject,
           journals: {
             creation_time => { notes: initial_comment },
             subject_change_time => { subject: "New subject", description: "Some not so long description." },
             comment_time => { notes: "A comment by a different user", user: create(:admin) }
           }).tap do |wp|
      Journal::CustomizableJournal.create!(journal: wp.journals[1],
                                           custom_field_id: custom_field.id,
                                           value: "*   [x] Task 1\n*   [ ] Task 2")
    end
  end

  let(:initial_subject) { "My Subject" }
  let(:initial_comment) { "First comment on this wp." }
  let(:comments_in_reverse) { false }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  let(:creation_journal) do
    work_package.journals.reload.first
  end
  let(:subject_change_journal) { work_package.journals[1] }
  let(:comment_journal) { work_package.journals[2] }

  current_user { user }

  before do
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
    allow(user.pref).to receive(:comments_sorting).and_return(comments_in_reverse ? "desc" : "asc")
    allow(user.pref).to receive(:comments_in_reverse_order?).and_return(comments_in_reverse)
  end

  shared_examples "shows activities in order" do
    let(:journals) do
      journals = [creation_journal, subject_change_journal, comment_journal]

      journals
    end

    it "shows activities in ascending order" do
      journals.each_with_index do |journal, idx|
        actual_index =
          if comments_in_reverse
            journals.length - idx
          else
            idx + 1
          end

        date_selector = ".work-package-details-activities-activity:nth-of-type(#{actual_index}) .activity-date"
        # Do not use :long format to match the printed date without double spaces
        # on the first 9 days of the month
        expect(page).to have_selector(date_selector,
                                      text: journal.created_at.to_date.strftime("%B %-d, %Y"))

        activity = page.find("#activity-#{idx + 1}")

        if journal.id != subject_change_journal.id
          expect(activity).to have_css(".op-user-activity--user-line", text: journal.user.name)
          expect(activity).to have_css(".user-comment > .message", text: journal.notes, visible: :all)
        end

        if activity == subject_change_journal
          expect(activity).to have_css(".work-package-details-activities-messages .message",
                                       count: 2)
          expect(activity).to have_css(".message",
                                       text: "Subject changed from #{initial_subject} " \
                                             "to #{journal.data.subject}")
        end
      end
    end
  end

  shared_examples "activity tab" do
    before do
      work_package_page.visit_tab! "activity"
      work_package_page.ensure_page_loaded
      expect(page).to have_css(".user-comment > .message",
                               text: initial_comment)
    end

    context "with permission" do
      let(:role) do
        create(:project_role, permissions: %i[view_work_packages add_work_package_notes])
      end
      let(:user) do
        create(:user,
               member_with_roles: { project => role })
      end

      context "with ascending comments" do
        let(:comments_in_reverse) { false }

        it_behaves_like "shows activities in order"
      end

      context "with reversed comments" do
        let(:comments_in_reverse) { true }

        it_behaves_like "shows activities in order"
      end

      it "can deep link to an activity" do
        visit "/work_packages/#{work_package.id}/activity#activity-#{comment_journal.id}"

        work_package_page.ensure_page_loaded
        expect(page).to have_css(".user-comment > .message",
                                 text: initial_comment)

        expect(page.current_url).to match /\/work_packages\/#{work_package.id}\/activity#activity-#{comment_journal.id}/
      end

      it "can toggle between activities and comments-only" do
        expect(page).to have_css(".work-package-details-activities-activity-contents", count: 3)
        expect(page).to have_css(".user-comment > .message", text: comment_journal.notes)

        # Show only comments
        find(".activity-comments--toggler").click

        # It should remove the middle
        expect(page).to have_css(".work-package-details-activities-activity-contents", count: 2)
        expect(page).to have_css(".user-comment > .message", text: initial_comment)
        expect(page).to have_css(".user-comment > .message", text: comment_journal.notes)

        # Show all again
        find(".activity-comments--toggler").click
        expect(page).to have_css(".work-package-details-activities-activity-contents", count: 3)
      end

      it "can quote a previous comment" do
        activity_tab.hover_action("1", :quote)

        field = TextEditorField.new work_package_page,
                                    "comment",
                                    selector: ".work-packages--activity--add-comment"

        field.expect_active!

        # Add our comment
        quote = field.input_element.text
        expect(quote).to include(initial_comment)
        field.input_element.base.send_keys "\nthis is some remark under a quote"
        field.submit_by_click

        expect(page).to have_css(".user-comment > .message", count: 3)
        expect(page).to have_css(".user-comment > .message blockquote")
      end
    end

    context "with no permission" do
      let(:role) do
        create(:project_role, permissions: [:view_work_packages])
      end
      let(:user) do
        create(:user,
               member_with_roles: { project => role })
      end

      it "shows the activities, but does not allow commenting" do
        expect(page).to have_no_css(".work-packages--activity--add-comment", visible: :visible)
      end
    end
  end

  context "if on split screen" do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }

    it_behaves_like "activity tab"
  end

  context "if on full screen" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

    it_behaves_like "activity tab"
  end
end
