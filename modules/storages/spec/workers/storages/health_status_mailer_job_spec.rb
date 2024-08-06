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

RSpec.describe Storages::HealthStatusMailerJob do
  let!(:user) { create(:user) }
  let!(:admin_user) { create(:admin) }
  let!(:storage) { create(:nextcloud_storage) }

  shared_examples "skips sending an email" do
    before do
      allow(described_class).to receive(:schedule).and_call_original
    end

    it "does not send an email" do
      expect do
        described_class.perform_now(storage:)
      end.not_to have_enqueued_mail(Storages::StoragesMailer, :notify_healthy)

      expect(described_class).not_to have_received(:schedule)
    end
  end

  describe "perform" do
    it "sends an email to all admin users if the storage is unhealthy" do
      storage.update!(health_status: "unhealthy")

      expect do
        described_class.perform_now(storage:)
      end.to(have_enqueued_mail(Storages::StoragesMailer, :notify_healthy)
              .with(admin_user, storage, storage.health_reason).at_most(:once)
              .and(have_enqueued_job(described_class).with(storage:)))
    end

    context "when the storage is unhealthy but notifications are disabled" do
      before { storage.update!(health_status: "unhealthy", health_notifications_enabled: false) }

      it_behaves_like "skips sending an email"
    end

    context "when the storage is healthy" do
      before { storage.update!(health_status: "healthy", health_notifications_enabled: true) }

      it_behaves_like "skips sending an email"
    end
  end
end
