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

RSpec.describe WorkPackages::ActivitiesTab::Journals::ItemComponent::Actions, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:author) { create(:user) }
  shared_let(:work_package) { create(:work_package, project:, author:) }

  let(:journal) do
    create(:work_package_journal, journable: work_package, user: journal_user, notes: "A comment", version: 2)
  end
  let(:journal_user) { author }
  let(:permissions) { [] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  before do
    render_inline(described_class.new(journal))
  end

  it "copies the sharable activity URL through the clipboard-copy element" do
    expect(page.find("clipboard-copy")["value"])
      .to end_with("/projects/#{work_package.project.identifier}" \
                   "/work_packages/#{work_package.id}/activity#comment-#{journal.id}")
  end

  context "without comment permissions" do
    it "does not offer edit or quote actions" do
      expect(page).to have_no_test_selector("op-wp-journal-#{journal.id}-edit")
      expect(page).to have_no_test_selector("op-wp-journal-#{journal.id}-quote")
    end
  end

  context "with permission to add comments and edit own comments" do
    let(:permissions) { %i[view_work_packages add_work_package_comments edit_own_work_package_comments] }

    it "can quote but cannot edit another user's comment" do
      expect(page).to have_no_test_selector("op-wp-journal-#{journal.id}-edit")
      expect(page).to have_test_selector("op-wp-journal-#{journal.id}-quote")
    end

    context "when the comment belongs to the current user" do
      let(:journal_user) { user }

      it "offers edit and quote actions" do
        expect(page).to have_test_selector("op-wp-journal-#{journal.id}-edit")
        expect(page).to have_test_selector("op-wp-journal-#{journal.id}-quote")
      end
    end
  end

  context "with permission to edit all comments" do
    let(:permissions) { %i[view_work_packages add_work_package_comments edit_work_package_comments] }

    it "offers edit and quote actions for another user's comment" do
      expect(page).to have_test_selector("op-wp-journal-#{journal.id}-edit")
      expect(page).to have_test_selector("op-wp-journal-#{journal.id}-quote")
    end
  end
end
