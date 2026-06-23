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
require_relative "../../support/pages/backlog"

RSpec.describe "Add existing work package", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:project) { create(:project) }
  shared_let(:sprint_a) { create(:sprint, project:, name: "Sprint 1") }
  shared_let(:sprint_b) { create(:sprint, project:, name: "Sprint 2") }
  shared_let(:bucket_a) { create(:backlog_bucket, project:, name: "Bucket A") }
  shared_let(:bucket_b) { create(:backlog_bucket, project:, name: "Bucket B") }

  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:permissions) do
    %i[
      add_work_packages
      create_sprints
      manage_sprint_items
      view_sprints
      view_work_packages
    ]
  end

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { user }

  context "when existing work package is in inbox" do
    let!(:work_package) { create(:work_package, project:) }

    it "can be added to a bucket" do
      backlogs_page.visit!
      backlogs_page.click_in_backlog_bucket_menu(bucket_a, "Add existing work package")

      within_modal "Add existing work package to #{bucket_a.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_backlog_bucket(work_package, bucket_a)
      backlogs_page.expect_no_inbox_item(work_package)

      backlogs_page.click_in_backlog_bucket_menu(bucket_a, "Add existing work package")
      within_modal "Add existing work package to #{bucket_a.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end

    it "can be added to a sprint" do
      backlogs_page.visit!
      backlogs_page.click_in_sprint_menu(sprint_a, "Add existing work package")

      within_modal "Add existing work package to #{sprint_a.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_sprint(work_package, sprint_a)
      backlogs_page.expect_no_inbox_item(work_package)

      backlogs_page.click_in_sprint_menu(sprint_a, "Add existing work package")
      within_modal "Add existing work package to #{sprint_a.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end
  end

  context "when existing work package is in a bucket" do
    let!(:work_package) { create(:work_package, project:, backlog_bucket: bucket_a) }

    it "can be added to inbox" do
      backlogs_page.visit!
      backlogs_page.click_in_inbox_menu("Add existing work package")

      within_modal "Add existing work package to #{I18n.t(:label_inbox)}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_inbox_item(work_package)
      backlogs_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)

      backlogs_page.click_in_inbox_menu("Add existing work package")
      within_modal "Add existing work package to #{I18n.t(:label_inbox)}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end

    it "can be added to another bucket" do
      backlogs_page.visit!
      backlogs_page.click_in_backlog_bucket_menu(bucket_b, "Add existing work package")

      within_modal "Add existing work package to #{bucket_b.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_backlog_bucket(work_package, bucket_b)
      backlogs_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)

      backlogs_page.click_in_backlog_bucket_menu(bucket_b, "Add existing work package")
      within_modal "Add existing work package to #{bucket_b.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end

    it "can be added to a sprint" do
      backlogs_page.visit!
      backlogs_page.click_in_sprint_menu(sprint_a, "Add existing work package")

      within_modal "Add existing work package to #{sprint_a.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_sprint(work_package, sprint_a)
      backlogs_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)

      backlogs_page.click_in_sprint_menu(sprint_a, "Add existing work package")
      within_modal "Add existing work package to #{sprint_a.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end
  end

  context "when existing work package is in a sprint" do
    let!(:work_package) { create(:work_package, project:, sprint: sprint_a) }

    it "can be added to inbox" do
      backlogs_page.visit!
      backlogs_page.click_in_inbox_menu("Add existing work package")

      within_modal "Add existing work package to #{I18n.t(:label_inbox)}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_inbox_item(work_package)
      backlogs_page.expect_work_package_not_in_sprint(work_package, sprint_a)

      backlogs_page.click_in_inbox_menu("Add existing work package")
      within_modal "Add existing work package to #{I18n.t(:label_inbox)}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end

    it "can be added to a bucket" do
      backlogs_page.visit!
      backlogs_page.click_in_backlog_bucket_menu(bucket_a, "Add existing work package")

      within_modal "Add existing work package to #{bucket_a.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_backlog_bucket(work_package, bucket_a)
      backlogs_page.expect_work_package_not_in_sprint(work_package, sprint_a)

      backlogs_page.click_in_backlog_bucket_menu(bucket_a, "Add existing work package")
      within_modal "Add existing work package to #{bucket_a.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end

    it "can be added to another sprint" do
      backlogs_page.visit!
      backlogs_page.click_in_sprint_menu(sprint_b, "Add existing work package")

      within_modal "Add existing work package to #{sprint_b.name}" do
        select_autocomplete(find("ng-select"), query: work_package.subject)
        wait_for_turbo_stream { click_on I18n.t(:button_add) }
      end

      backlogs_page.expect_work_package_in_sprint(work_package, sprint_b)
      backlogs_page.expect_work_package_not_in_sprint(work_package, sprint_a)

      backlogs_page.click_in_sprint_menu(sprint_b, "Add existing work package")
      within_modal "Add existing work package to #{sprint_b.name}" do
        search_autocomplete(find("ng-select"), query: work_package.subject)
        expect(page).to have_no_css(".ng-option", text: work_package.subject, wait: 5)
      end
    end
  end

  context "when not having enough permissions" do
    let(:permissions) { super() - %i[manage_sprint_items] }

    it "hides the menu item to add existing work packages" do
      backlogs_page.visit!

      backlogs_page.within_sprint_menu(sprint_a) do |menu|
        expect(menu).to have_no_selector(:menuitem, text: "Add existing work package")
      end

      backlogs_page.within_backlog_bucket_menu(bucket_a) do |menu|
        expect(menu).to have_no_selector(:menuitem, text: "Add existing work package")
      end

      # only one action can be there, so without it menu will not be rendered
      backlogs_page.expect_no_inbox_menu
    end
  end
end
