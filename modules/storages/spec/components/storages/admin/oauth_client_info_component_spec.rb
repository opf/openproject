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

RSpec.describe Storages::Admin::OAuthClientInfoComponent, type: :component do # rubocop:disable RSpec/SpecFilePathFormat
  describe "#edit_icon_button_options" do
    context "with oauth client configured" do
      it "returns false, does not render view component" do
        storage = build_stubbed(:nextcloud_storage,
                                oauth_client: build_stubbed(:oauth_client))
        component = described_class.new(storage:, oauth_client: storage.oauth_client)
        expect(component.edit_icon_button_options)
          .to include(icon: :sync,
                      data: { turbo_confirm:
                                "This action will reset the current OAuth credentials. After confirming you will " \
                                "have to enter new credentials from the storage provider and all users will have " \
                                "to authorize against Nextcloud again. Are you sure you want to proceed?",
                              turbo_stream: true })
      end
    end

    context "without oauth client" do
      it "returns true, renders view component" do
        storage = build_stubbed(:nextcloud_storage)
        component = described_class.new(storage:, oauth_client: nil)

        edit_icon_button_data_options = component.edit_icon_button_options
        expect(edit_icon_button_data_options).to include(icon: :pencil, data: { turbo_stream: true })
        expect(edit_icon_button_data_options[:data]).not_to include(:confirm)
      end
    end
  end
end
