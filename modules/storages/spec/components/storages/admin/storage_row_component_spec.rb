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
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::Admin::StorageRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:storage_row_component) { described_class.new(storage) }

  before do
    render_inline(storage_row_component)
  end

  describe "Nextcloud storage" do
    shared_examples "a Nextcloud storage row" do
      it "render the storage name" do
        expect(page).to have_link(storage.name, href: edit_admin_settings_storage_path(storage))
      end

      it "renders the storage creator" do
        pending "Invisible on small screens: Find a way to render inline"
        expect(page).to have_test_selector("storage-creator", text: storage.creator.name)
      end

      it "renders the storage provider" do
        expect(page).to have_test_selector("storage-provider", text: "Nextcloud")
      end

      it "renders the storage host" do
        expect(page).to have_test_selector("storage-host", text: storage.host)
      end
    end

    context "with complete storage" do
      shared_let(:storage) { create(:nextcloud_storage_with_local_connection) }

      it_behaves_like "a Nextcloud storage row"

      it "does not show an incomplete label" do
        expect(page).not_to have_test_selector("label-incomplete")
      end
    end

    context "with incomplete storage" do
      shared_let(:storage) { create(:nextcloud_storage) }

      it_behaves_like "a Nextcloud storage row"

      it 'renders an "Incomplete" label' do
        expect(page).to have_test_selector("label-incomplete", text: "Incomplete")
      end
    end

    context "with unhealthy storage" do
      shared_let(:storage) do
        create(:nextcloud_storage_with_complete_configuration, :as_unhealthy)
      end

      it_behaves_like "a Nextcloud storage row"

      it 'renders an "Error" label' do
        expect(page).to have_test_selector("storage-health-label-error", text: "Error")
      end
    end
  end

  describe "OneDrive/SharePoint storage" do
    shared_examples "a OneDrive/SharePoint storage row" do
      it "render the storage name" do
        expect(page).to have_link(storage.name, href: edit_admin_settings_storage_path(storage))
      end

      it "renders the storage creator" do
        pending "Invisible on small screens: Find a way to render inline"
        expect(page).to have_test_selector("storage-creator", text: storage.creator.name)
      end

      it "renders the storage provider" do
        expect(page).to have_test_selector("storage-provider", text: "OneDrive/SharePoint")
      end
    end

    context "with complete storage" do
      shared_let(:storage) { create(:sharepoint_dev_drive_storage) }

      it_behaves_like "a OneDrive/SharePoint storage row"

      it "does not show an incomplete label" do
        expect(page).not_to have_test_selector("label-incomplete")
      end
    end

    context "with incomplete storage" do
      shared_let(:storage) { create(:one_drive_storage) }

      it_behaves_like "a OneDrive/SharePoint storage row"

      it 'renders an "Incomplete" label' do
        expect(page).to have_test_selector("label-incomplete", text: "Incomplete")
      end
    end
  end
end
