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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package revision component", :js, :with_cuprite do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package, project:) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  let(:repository) { create(:repository_subversion, project:) }
  let(:revision_time) { 2.days.ago }
  let(:revision_message) { "A commit message for a revision" }
  let(:revision_identifier) { "123" }

  current_user { user }

  before do
    # Enable subversion in settings
    Setting.enabled_scm = Setting.enabled_scm << repository.vendor

    # Associate changeset with work package
    work_package.changesets << changeset

    wp_page.visit!
    wp_page.wait_for_activity_tab
  end

  shared_examples "shows revision details" do
    it "displays the revision details correctly" do
      # Verify revision message is displayed
      expect(page).to have_test_selector("op-revision-notes-body", text: revision_message)

      # Verify revision link is displayed with correct identifier
      expect(page).to have_link(revision_identifier,
                                href: show_revision_project_repository_path(project_id: project.id, rev: revision_identifier))

      # Verify revision is shown when filter is set to all
      activity_tab.filter_journals(:all)
      expect(page).to have_test_selector("op-revision-notes-body", text: revision_message)

      # Verify revision is shown when filter is set to only changes
      activity_tab.filter_journals(:only_changes)
      expect(page).to have_test_selector("op-revision-notes-body", text: revision_message)

      # Verify revision is not shown when filter is set to only comments
      activity_tab.filter_journals(:only_comments)
      expect(page).not_to have_test_selector("op-revision-notes-body", text: revision_message)
    end
  end

  context "with unmapped repository user" do
    let!(:changeset) do
      create(:changeset,
             comments: revision_message,
             committed_on: revision_time,
             repository:,
             committer: "a_person",
             revision: revision_identifier)
    end

    it "displays the committer name" do
      expect(page).to have_text("a_person")
    end

    include_examples "shows revision details"
  end

  context "with mapped repository user" do
    let(:repository_user) { create(:user, firstname: "Repository", lastname: "User") }
    let!(:changeset) do
      create(:changeset,
             comments: revision_message,
             committed_on: revision_time,
             repository:,
             committer: repository_user.login,
             user: repository_user,
             revision: revision_identifier)
    end

    it "displays the mapped user with avatar" do
      expect(page).to have_test_selector("op-revision-header")
      within(page.find_test_selector("op-revision-header")) do
        expect(page).to have_test_selector("op-principal")
        expect(page).to have_text("Repository User")
      end
    end

    include_examples "shows revision details"
  end
end
