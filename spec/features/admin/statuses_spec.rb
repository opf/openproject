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

RSpec.describe "Statuses admin page", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:status_new) { create(:status, name: "New", default_done_ratio: 0, is_default: true) }
  shared_let(:status_in_progress) { create(:status, name: "In Progress", default_done_ratio: 40) }
  shared_let(:status_done) { create(:status, name: "Done", default_done_ratio: 100, is_closed: true, is_readonly: true) }

  before do
    login_as(admin)
  end

  describe "index page" do
    # Reordering persists across examples, so each one starts from a known order.
    before do
      [status_new, status_in_progress, status_done].each_with_index do |status, index|
        status.update_column(:position, index + 1)
      end
    end

    let(:statuses_page) { Pages::Admin::Statuses.new }

    it "reorders statuses through the action menu" do
      statuses_page.visit!

      statuses_page.expect_listed("New", "In Progress", "Done")

      statuses_page.click_status_action(status_new, action: "Move to bottom")

      expect(page).to have_text("Successful update.")
      statuses_page.expect_listed("In Progress", "Done", "New")

      statuses_page.click_status_action(status_done, action: "Move up")

      statuses_page.expect_listed("Done", "In Progress", "New")
    end

    it "offers no upward move on the first status, and no downward move on the last" do
      statuses_page.visit!

      statuses_page.within_status(status_new) do
        click_on accessible_name: "Status actions"
        expect(page).to have_no_button("Move to top")
        expect(page).to have_button("Move to bottom")
      end
    end

    it "reorders statuses by dragging them" do
      statuses_page.visit!

      statuses_page.drag_status(from_index: 0, to_index: 2)
      wait_for_network_idle

      statuses_page.expect_listed("In Progress", "Done", "New")

      statuses_page.reload!
      statuses_page.expect_listed("In Progress", "Done", "New")
    end

    describe "quick filters" do
      shared_let(:task) { create(:type, name: "Task") }
      shared_let(:manager) { create(:project_role, name: "Manager") }
      shared_let(:member) { create(:project_role, name: "Member") }
      shared_let(:task_manager_transition) do
        create(:workflow, type: task, role: manager, old_status: status_new, new_status: status_in_progress)
      end

      it "narrows the list to the statuses of the selected type and role" do
        statuses_page.visit!
        statuses_page.expect_listed("New", "In Progress", "Done")

        statuses_page.filter_by_type(task)

        statuses_page.expect_listed("New", "In Progress")

        statuses_page.filter_by_role(member)

        statuses_page.expect_listed
      end

      it "offers no reordering while filtered, since positions are global" do
        statuses_page.visit!
        expect(page).to have_css(".DragHandle")

        statuses_page.filter_by_type(task)

        statuses_page.expect_no_reordering
      end
    end

    describe "pagination", with_settings: { per_page_options: "2, 100" } do
      it "pages the list, and a larger page size widens what drag and drop can reach" do
        statuses_page.visit!

        statuses_page.expect_listed("New", "In Progress")

        statuses_page.set_page_size(100)

        statuses_page.expect_listed("New", "In Progress", "Done")

        statuses_page.drag_status(from_index: 0, to_index: 2)
        wait_for_network_idle

        statuses_page.expect_listed("In Progress", "Done", "New")
      end

      it "keeps the reader on their page after a move" do
        statuses_page.visit!
        statuses_page.go_to_page(2)

        statuses_page.expect_listed("Done")

        statuses_page.click_status_action(status_done, action: "Move up")

        statuses_page.expect_listed("In Progress")
        expect(Status.order(:position).pluck(:name)).to eq(["New", "Done", "In Progress"])
      end
    end
  end

  describe "create page" do
    context "with enterprise edition", with_ee: %i[readonly_work_packages] do
      it "has 'is read-only' checkbox unchecked and disabled only when 'is default' is checked (mutually exclusive)" do
        visit new_status_path

        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default))

        # given read-only is checked, when is_default is checked then read-only should become unchecked and disabled
        page.check(Status.human_attribute_name(:is_readonly))
        expect(page).to have_checked_field(Status.human_attribute_name(:is_readonly))
        page.check(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # given read-only is disabled, when is_default is unchecked then read-only should become enabled
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: false)
      end
    end

    context "with commmunity edition", with_ee: false do
      it "has 'is read-only' checkbox always disabled" do
        visit new_status_path

        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # check that it remains unchecked
        page.check(Status.human_attribute_name(:is_default))
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)
      end
    end
  end

  describe "edit page" do
    it "has 'is default' checkbox disabled for the default status (cannot be unchecked)" do
      visit statuses_path

      click_on "New"
      expect(page).to have_checked_field(Status.human_attribute_name(:is_default), disabled: true)

      page.go_back
      click_on "In Progress"
      expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default), disabled: false)
    end

    context "with enterprise edition", with_ee: %i[readonly_work_packages] do
      it "has 'is read-only' checkbox unchecked and disabled only when 'is default' is checked (mutually exclusive)" do
        visit statuses_path

        click_on "New"
        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        page.go_back
        click_on "In Progress"
        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default))

        # given read-only is checked, when is_default is checked then read-only should become unchecked and disabled
        page.check(Status.human_attribute_name(:is_readonly))
        expect(page).to have_checked_field(Status.human_attribute_name(:is_readonly))
        page.check(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # given read-only is disabled, when is_default is unchecked then read-only should become enabled
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: false)
      end
    end

    context "with commmunity edition", with_ee: false do
      it "has 'is read-only' checkbox always disabled" do
        visit statuses_path

        click_on "In Progress"
        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # check that it remains unchecked
        page.check(Status.human_attribute_name(:is_default))
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # readonly statuses are no longer readonly if enterprise edition is not enabled
        page.go_back
        click_on "Done"
        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)
      end
    end
  end
end
