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

RSpec.describe Storages::Admin::SidePanel::HealthNotificationsComponent, type: :component do
  context "when subscribed to email notifications" do
    let(:storage) { build_stubbed(:nextcloud_storage, :with_health_notifications_enabled, :as_automatically_managed) }

    before do
      render_inline(described_class.new(storage:))
    end

    it "renders an unsubscribe option with info" do
      expect(page).to have_css("input[type=hidden][value='0']", visible: :hidden)
      expect(page).to have_test_selector(
        "storage-health-notifications-description",
        text: "All administrators receive health status email notifications for this storage."
      )
      expect(page).to have_button("Unsubscribe")
    end
  end

  context "when unsubscribed to email notifications" do
    let(:storage) { build_stubbed(:nextcloud_storage, :with_health_notifications_disabled, :as_automatically_managed) }

    before do
      render_inline(described_class.new(storage:))
    end

    it "renders an unsubscribe option with info" do
      expect(page).to have_css("input[type=hidden][value='1']", visible: :hidden)
      expect(page).to have_test_selector(
        "storage-health-notifications-description",
        text: "Health status email notifications for this storage have been turned off for all administrators."
      )
      expect(page).to have_button("Subscribe")
    end
  end

  context "with non-automatically managed storage" do
    let(:storage) { build_stubbed(:nextcloud_storage, :as_not_automatically_managed) }

    it "does not render" do
      render_inline described_class.new(storage:)
      expect(page.text).to be_empty
    end
  end
end
