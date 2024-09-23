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

RSpec.describe Storages::Admin::StorageListComponent, type: :component do
  shared_let(:nextcloud_storage) { create(:nextcloud_storage) }
  shared_let(:one_drive_storage) { create(:one_drive_storage) }

  let(:storages) { [nextcloud_storage, one_drive_storage] }

  subject(:storage_list_component) { described_class.new(storages) }

  before do
    render_inline(storage_list_component)
  end

  context "with storages" do
    it "lists all storages" do
      expect(page).to have_list_item(count: 2)
      expect(page).to have_list_item(nextcloud_storage.name)
      expect(page).to have_list_item(one_drive_storage.name)
    end
  end

  context "with no storages" do
    let(:storages) { [] }

    it "renders a blank slate" do
      expect(page).to have_text("You don't have any storages yet.")
    end
  end
end
