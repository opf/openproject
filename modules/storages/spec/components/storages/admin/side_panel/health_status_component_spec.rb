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

RSpec.describe Storages::Admin::SidePanel::HealthStatusComponent, type: :component do
  frozen_date_time = Time.zone.local(2023, 11, 28, 1, 2, 3)

  subject(:health_status_component) { described_class.new(storage:) }

  before do
    render_inline(health_status_component)
  end

  context "with healthy storage" do
    shared_let(:storage) do
      travel_to(frozen_date_time) do
        create(:nextcloud_storage_with_complete_configuration, :as_healthy)
      end
    end

    it "shows a healthy status" do
      expect(page).to have_test_selector("storage-health-status", text: "Healthy")
      expect(page).to have_test_selector("storage-health-checked-at", text: "Last checked 11/28/2023 01:02 AM")
    end
  end

  context "with storage health pending" do
    shared_let(:storage) do
      travel_to(frozen_date_time) do
        create(:nextcloud_storage_with_complete_configuration)
      end
    end

    it "shows pending label" do
      expect(page).to have_test_selector("storage-health-status", text: "Pending")
    end
  end

  context "with unhealthy storage" do
    shared_let(:storage) do
      travel_to(frozen_date_time) do
        create(:nextcloud_storage_with_complete_configuration, :as_unhealthy)
      end
    end

    it "shows an error status" do
      expect(page).to have_test_selector("storage-health-status", text: "Error")
      expect(page).to have_test_selector("storage-health-error", text: "Error code: description since 11/28/2023 01:02 AM")
    end
  end

  context "with unhealthy storage, long reason" do
    shared_let(:storage) do
      travel_to(frozen_date_time) do
        create(:nextcloud_storage_with_complete_configuration, :as_unhealthy_long_reason)
      end
    end

    it "shows a formatted error reason" do
      expect(page).to have_test_selector("storage-health-status", text: "Error")
      expect(page).to have_test_selector("storage-health-error",
                                         text: "Unauthorized: Outbound request not authorized since 11/28/2023 01:02 AM")
    end
  end
end
