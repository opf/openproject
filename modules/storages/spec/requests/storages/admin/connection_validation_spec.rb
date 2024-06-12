#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "connection validation", :skip_csrf do
  describe "POST /admin/settings/storages/:id/connection_validation/validate_connection" do
    let(:storage) { create(:one_drive_storage) }
    let(:user) { create(:admin) }
    let(:validator) do
      double = instance_double(Storages::Peripherals::OneDriveConnectionValidator)
      allow(double).to receive_messages(validate: validation_result)
      double
    end
    let(:validation_result) do
      Storages::ConnectionValidation.new(icon: "check-circle", scheme: :default, description: "Successful!")
    end

    current_user { user }

    before do
      allow(Storages::Peripherals::OneDriveConnectionValidator).to receive(:new).and_return(validator)
    end

    it "returns a connection validation result" do
      response = post validate_connection_admin_settings_storage_connection_validation_path(storage.id, format: :turbo_stream)
      expect(response.status).to eq(200)

      doc = Nokogiri::HTML(response.body)
    end
  end
end
