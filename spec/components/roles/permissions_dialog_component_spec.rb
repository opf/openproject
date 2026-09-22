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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Roles::PermissionsDialogComponent, type: :component do
  subject do
    render_inline(described_class.new(role))
    page
  end

  context "with a project role" do
    let(:role) do
      build_stubbed(:project_role, permissions: %i[manage_members view_work_packages add_work_package_attachments])
    end

    it "renders a dialog titled after the role" do
      expect(subject).to have_element :dialog
      expect(subject).to have_heading "Permissions of \"#{role.name}\""
    end

    it "groups the granted permissions by module" do
      expect(subject).to have_heading "Project"
      expect(subject).to have_heading "Work packages and Gantt charts"
    end

    it "renders label and description of the granted permissions" do
      expect(subject).to have_text I18n.t(:permission_manage_members)
      expect(subject).to have_text I18n.t(:permission_add_work_package_attachments)
      expect(subject).to have_text I18n.t(:permission_add_work_package_attachments_explanation)
    end

    it "omits permissions the role does not grant" do
      expect(subject).to have_no_text I18n.t(:permission_delete_work_packages)
    end

    it "lists the public permissions as implicitly granted" do
      expect(subject).to have_text I18n.t(:permission_view_project)
      expect(subject).to have_text I18n.t("roles.permissions_dialog.implicit_permission")
    end

    it "renders a collapsible, expanded list per module" do
      expect(subject).to have_css "collapsible-header", minimum: 2
      expect(subject).to have_no_css ".CollapsibleHeader--collapsed"
    end

    it "counts the permissions of each module" do
      expect(subject).to have_css "[aria-label='1 permission']"
    end
  end

  context "with a global role" do
    let(:role) { build_stubbed(:global_role, permissions: %i[add_project]) }

    it "labels the module-less group as global" do
      expect(subject).to have_heading I18n.t(:label_global)
      expect(subject).to have_text I18n.t(:permission_add_project)
    end

    it "does not add the public project permissions" do
      expect(subject).to have_no_text I18n.t(:permission_view_project)
    end
  end

  context "with a role granting nothing" do
    let(:role) { build_stubbed(:global_role, permissions: []) }

    it "renders a notice instead of sections" do
      expect(subject).to have_text I18n.t("roles.permissions_dialog.no_permissions")
    end
  end

  describe "the footer spacing" do
    let(:role) { build_stubbed(:project_role, permissions: %i[view_work_packages]) }

    it "separates the body from the footer" do
      expect(subject).to have_css ".Overlay-body.mb-3"
      expect(subject).to have_css ".Overlay-footer--divided"
    end
  end

  describe "the edit button" do
    include Rails.application.routes.url_helpers

    let(:role) { build_stubbed(:project_role, permissions: %i[view_work_packages]) }

    context "when the current user is an admin" do
      current_user { build_stubbed(:admin) }

      it "links to the role permissions form" do
        expect(subject).to have_css "a[data-test-selector='#{described_class::TEST_SELECTOR}-edit']",
                                    text: I18n.t("roles.permissions_dialog.edit_permissions")
        expect(subject).to have_css "a[href='#{edit_role_path(role)}']"
      end
    end

    context "when the current user is not an admin" do
      current_user { build_stubbed(:user) }

      it "is omitted" do
        expect(subject).to have_no_css "[data-test-selector='#{described_class::TEST_SELECTOR}-edit']"
        expect(subject).to have_button I18n.t(:button_close)
      end
    end
  end
end
