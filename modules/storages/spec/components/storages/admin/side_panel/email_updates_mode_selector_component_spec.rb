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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::Admin::SidePanel::EmailUpdatesModeSelectorComponent, type: :component do
  describe "storage without automatically managed project folders" do
    let(:storage) { build_stubbed(:nextcloud_storage, :as_not_automatically_managed) }

    it "does not render" do
      render_inline described_class.new(storage:)
      expect(page.text).to be_empty
    end
  end

  describe "storage with automatically managed project folders" do
    before do
      render_inline(described_class.new(storage:))
    end

    describe "email notifications" do
      context "when email notifications are enabled" do
        let(:storage) { build_stubbed(:nextcloud_storage, :with_health_notifications_enabled, :as_automatically_managed) }

        it "renders a 'Disable' option with info" do
          text = "Admins will receive updates by email when there are important updates."
          expect(page).to have_test_selector("email-updates-mode-selector", text: text)
          expect(page).to have_selector(:link_or_button, "Disable")
        end
      end

      context "when email notifications are disabled" do
        let(:storage) { build_stubbed(:nextcloud_storage, :with_health_notifications_disabled, :as_automatically_managed) }

        it "renders an 'Enable' option with info" do
          text = "Admins will not receive updates by email when there are important updates."
          expect(page).to have_test_selector("email-updates-mode-selector", text:)
          expect(page).to have_selector(:link_or_button, "Enable")
        end
      end
    end
  end
end
