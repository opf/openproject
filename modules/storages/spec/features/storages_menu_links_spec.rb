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
require_module_spec_helper

RSpec.describe "Storage links in project menu" do
  include EnsureConnectionPathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking storages]) }
  shared_let(:storage_configured_linked1) { create(:nextcloud_storage_configured, :as_automatically_managed, name: "Storage 1") }
  shared_let(:project_storage1) do
    create(:project_storage, :as_automatically_managed, project:, storage: storage_configured_linked1)
  end
  shared_let(:storage_configured_linked2) { create(:nextcloud_storage_configured, name: "Storage 2") }
  shared_let(:project_storage2) do
    create(:project_storage, project_folder_mode: "inactive", project:, storage: storage_configured_linked2)
  end
  shared_let(:storage_configured_linked3) { create(:nextcloud_storage_configured, name: "Storage 3") }
  shared_let(:project_storage3) do
    create(:project_storage, project_folder_mode: "manual", project:, storage: storage_configured_linked3)
  end
  shared_let(:storage_configured_unlinked) { create(:nextcloud_storage_configured, name: "Storage 4") }
  shared_let(:storage_unconfigured_linked) { create(:nextcloud_storage, name: "Storage 5") }
  shared_let(:project_storage4) { create(:project_storage, project:, storage: storage_unconfigured_linked) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before do
    login_as(user)
    visit(project_path(project))
  end

  context "if user is an admin but not a member of the project" do
    let(:user) { create(:admin) }

    it "has no links to enabled storage" do
      visit(project_path(id: project.id))

      expect(page).to have_no_link(storage_configured_linked1.name)
      expect(page).to have_no_link(storage_configured_linked2.name)
      expect(page).to have_no_link(storage_configured_linked3.name)
      expect(page).to have_no_link(storage_configured_unlinked.name)
      expect(page).to have_no_link(storage_unconfigured_linked.name)
    end
  end

  context "if user has permission" do
    context "to read_files and view_file_links" do
      let(:permissions) { %i[view_file_links read_files] }

      it "has links to all enabled storages" do
        visit(project_path(id: project.id))

        expect(page).to have_link(storage_configured_linked1.name, href: ensure_connection_path(project_storage1))
        expect(page).to have_link(storage_configured_linked2.name, href: ensure_connection_path(project_storage2))
        expect(page).to have_link(storage_configured_linked3.name, href: ensure_connection_path(project_storage3))
        expect(page).to have_no_link(storage_configured_unlinked.name)
        expect(page).to have_no_link(storage_unconfigured_linked.name)
      end

      context "when OP has been installed behind prefix" do
        let(:prefix) { "/qwerty" }

        before { allow(OpenProject::Configuration).to receive(:rails_relative_url_root).and_return(prefix) }

        it "has all links prefixed" do
          visit(project_path(id: project.id))

          expect(page).to have_link(storage_configured_linked1.name, href: ensure_connection_path(project_storage1))
          expect(page).to have_link(storage_configured_linked2.name, href: ensure_connection_path(project_storage2))
          expect(page).to have_link(storage_configured_linked3.name, href: ensure_connection_path(project_storage3))
          expect(page).to have_no_link(storage_configured_unlinked.name)
          expect(page).to have_no_link(storage_unconfigured_linked.name)
        end
      end
    end

    context "to read_files" do
      let(:permissions) { %i[read_files] }

      it "has no links to enabled storages" do
        visit(project_path(id: project.id))

        expect(page).to have_no_link(storage_configured_linked1.name)
        expect(page).to have_no_link(storage_configured_linked2.name)
        expect(page).to have_no_link(storage_configured_linked3.name)
        expect(page).to have_no_link(storage_configured_unlinked.name)
        expect(page).to have_no_link(storage_unconfigured_linked.name)
      end
    end

    context "to view_file_links" do
      let(:permissions) { %i[view_file_links] }

      it "has links to enabled storages apart from automatically managed" do
        visit(project_path(id: project.id))

        expect(page).to have_no_link(storage_configured_linked1.name, href: ensure_connection_path(project_storage1))
        expect(page).to have_link(storage_configured_linked2.name, href: ensure_connection_path(project_storage2))
        expect(page).to have_link(storage_configured_linked3.name, href: ensure_connection_path(project_storage3))
        expect(page).to have_no_link(storage_configured_unlinked.name)
        expect(page).to have_no_link(storage_unconfigured_linked.name)
      end
    end
  end

  context "if user has no permission to see storage links" do
    let(:permissions) { %i[] }

    it "has no links to enabled storages" do
      visit(project_path(id: project.id))

      expect(page).to have_no_link(storage_configured_linked1.name)
      expect(page).to have_no_link(storage_configured_linked2.name)
      expect(page).to have_no_link(storage_configured_unlinked.name)
      expect(page).to have_no_link(storage_unconfigured_linked.name)
    end
  end
end
