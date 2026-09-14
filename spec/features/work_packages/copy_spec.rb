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

RSpec.describe "Work package copy", :js, :selenium do
  let(:user) do
    create(:user,
           member_with_roles: { project => create_role })
  end
  let(:work_flow) do
    create(:workflow,
           role: create_role,
           type_id: original_work_package.type_id,
           old_status: original_work_package.status,
           new_status: create(:status))
  end

  let(:create_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           add_work_packages
                           copy_work_packages
                           manage_work_package_relations
                           edit_work_packages
                           assign_versions])
  end
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }
  let(:original_work_package) do
    build(:work_package,
          project:,
          assigned_to: assignee,
          responsible:,
          version:,
          type:,
          author:)
  end
  let(:role) { build(:project_role, permissions: %i[view_work_packages work_package_assigned]) }
  let(:assignee) do
    create(:user,
           firstname: "An",
           lastname: "assignee",
           member_with_roles: { project => role })
  end
  let(:responsible) do
    create(:user,
           firstname: "The",
           lastname: "responsible",
           member_with_roles: { project => role })
  end
  let(:author) do
    create(:user,
           firstname: "The",
           lastname: "author",
           member_with_roles: { project => role })
  end
  let(:version) do
    build(:version,
          project:)
  end

  let(:relations_tab) { Components::WorkPackages::Relations.new(original_work_package) }

  before do
    login_as(user)
    original_work_package.save!
    work_flow.save!
  end

  it "on fullscreen page" do
    original_work_package_page = Pages::FullWorkPackage.new(original_work_package, project)
    to_copy_work_package_page = original_work_package_page.visit_copy!

    to_copy_work_package_page.expect_current_path
    to_copy_work_package_page.expect_fully_loaded

    to_copy_work_package_page.fill_in_attributes Description: "Copied WP Description"
    to_copy_work_package_page.save!

    expect(page).to have_css(".op-toast--content",
                             text: I18n.t("js.notice_successful_create"),
                             wait: 20)

    copied_work_package = WorkPackage.order(created_at: "desc").first

    expect(copied_work_package).not_to eql original_work_package

    work_package_page = Pages::FullWorkPackage.new(copied_work_package, project)
    activity_tab = Components::WorkPackages::Activities.new(copied_work_package)
    work_package_page.ensure_page_loaded
    work_package_page.expect_attributes Subject: original_work_package.subject,
                                        Description: "Copied WP Description",
                                        TargetVersions: original_work_package.target_versions.first,
                                        Priority: original_work_package.priority,
                                        Assignee: original_work_package.assigned_to.name,
                                        Responsible: original_work_package.responsible.name

    activity_tab.expect_journal_details_header(text: user.name)
    work_package_page.expect_current_path

    work_package_page.visit_tab! :relations
    expect_angular_frontend_initialized
    work_package_page.expect_subject
    loading_indicator_saveguard

    relations_tab.expect_relation_group(:relates)
    relations_tab.expect_relation_by_text(original_work_package.subject)
  end

  describe "when source work package has an attachment" do
    it "still allows copying through menu (Regression #30518)" do
      wp_page = Pages::FullWorkPackage.new(original_work_package, project)
      wp_page.visit!
      wp_page.ensure_page_loaded

      wp_page.select_from_context_menu("Duplicate")

      to_copy_work_package_page = Pages::FullWorkPackageCreate.new(original_work_package:)
      to_copy_work_package_page.update_attributes Description: "Copied WP Description"
      to_copy_work_package_page.save!

      wp_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_create")
    end
  end

  describe "when source work package is an automatically scheduled parent" do
    before do
      create(:work_package, project:, parent: original_work_package, subject: "Child")
      original_work_package.update!(schedule_manually: false)
    end

    it "still allows copying through menu (Bug #69309)" do
      wp_page = Pages::FullWorkPackage.new(original_work_package, project)
      wp_page.visit!
      wp_page.ensure_page_loaded

      wp_page.select_from_context_menu("Duplicate")

      to_copy_work_package_page = Pages::FullWorkPackageCreate.new(original_work_package:)
      to_copy_work_package_page.save!

      wp_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_create")
    end
  end
end
