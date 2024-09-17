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
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::Admin::AccessManagementComponent, type: :component do
  subject(:access_management_component) { described_class.new(storage) }

  before do
    render_inline(access_management_component)
  end

  context "on a pristine form" do
    let(:storage) { Storages::OneDriveStorage.new }

    it "renders the access management description" do
      expect(page).to have_text("Select the type of management of user access and folder creation.")
      expect(page).not_to have_test_selector("label-access_management_configured-status")
    end
  end

  context "on a form with access management set to automatic management enabled" do
    let(:storage) { create(:one_drive_storage, :as_automatically_managed) }

    it "renders the access management description" do
      expect(page).to have_text("Automatically managed access and folders")
      expect(page).to have_test_selector("label-access_management_configured-status", text: "Completed")
    end
  end

  context "on a form with access management set to manual management enabled" do
    let(:storage) { create(:one_drive_storage, :as_not_automatically_managed) }

    it "renders the access management description" do
      expect(page).to have_text("Manually managed access and folders")
      expect(page).to have_test_selector("label-access_management_configured-status", text: "Completed")
    end
  end
end
