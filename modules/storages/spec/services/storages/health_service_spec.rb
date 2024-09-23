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

RSpec.describe Storages::HealthService do
  let(:storage) { create(:nextcloud_storage) }
  let(:health_service) { described_class.new(storage:) }

  describe "health attributes" do
    it "can be marked as healthy or unhealthy" do
      healthy_time = Time.parse "2021-03-14T15:17:00Z"
      unhealthy_time = Time.parse "2023-03-14T15:17:00Z"

      Timecop.freeze(healthy_time) do
        expect do
          health_service.healthy
        end.to(change(storage, :health_changed_at).to(healthy_time)
                                                  .and(change(storage, :health_status).from("pending").to("healthy")))
        expect(storage.health_healthy?).to be(true)
        expect(storage.health_unhealthy?).to be(false)
      end

      Timecop.freeze(unhealthy_time) do
        expect do
          health_service.unhealthy(reason: "thou_shall_not_pass_error")
        end.to(change(storage, :health_changed_at).from(healthy_time).to(unhealthy_time)
                                                  .and(change(storage, :health_status).from("healthy").to("unhealthy"))
                                                  .and(change(storage, :health_reason).from(nil).to("thou_shall_not_pass_error")))
      end
      expect(storage.health_healthy?).to be(false)
      expect(storage.health_unhealthy?).to be(true)
    end

    # rubocop:disable RSpec/ExampleLength
    it "has the correct changed_at and checked_at attributes" do
      healthy_time = Time.parse "2021-03-14T15:17:00Z"
      unhealthy_time_a = Time.parse "2023-03-14T00:00:00Z"
      unhealthy_time_b = Time.parse "2023-03-14T22:22:00Z"
      unhealthy_time_c = Time.parse "2023-03-14T11:11:00Z"
      reason_a = "thou_shall_not_pass_error"
      reason_b = "inception_error"

      Timecop.freeze(healthy_time) do
        expect do
          health_service.healthy
        end.to(change(storage, :health_changed_at).to(healthy_time)
                                                  .and(change(storage, :health_checked_at).to(healthy_time)))
      end

      Timecop.freeze(unhealthy_time_a) do
        expect do
          health_service.unhealthy(reason: reason_a)
        end.to(change(storage, :health_changed_at)
                 .from(healthy_time).to(unhealthy_time_a)
                 .and(change(storage, :health_reason)
                        .from(nil).to(reason_a))
                 .and(change(storage, :health_checked_at)
                        .from(healthy_time).to(unhealthy_time_a)))
      end

      Timecop.freeze(unhealthy_time_b) do
        expect do
          health_service.unhealthy(reason: reason_a)
        end.to(change(storage, :health_checked_at)
                 .from(unhealthy_time_a).to(unhealthy_time_b))
        expect(storage.health_changed_at).to eq(unhealthy_time_a)
      end

      Timecop.freeze(unhealthy_time_c) do
        expect do
          health_service.unhealthy(reason: reason_b)
        end.to(change(storage, :health_checked_at)
                 .from(unhealthy_time_b).to(unhealthy_time_c)
                 .and(change(storage, :health_changed_at)
                        .from(unhealthy_time_a).to(unhealthy_time_c))
                 .and(change(storage, :health_reason)
                        .from(reason_a).to(reason_b)))
      end
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "Health notifications" do
    let(:user) { create(:user) }
    let(:admin_user) { create(:admin) }
    let(:role) { create(:project_role) }
    let(:storage) { create(:nextcloud_storage) }
    let!(:project_storage) { create(:project_storage, project:, storage:) }

    let(:project) do
      create(:project,
             members: { user => role,
                        admin_user => role },
             enabled_module_names: %i[storages])
    end

    context "when the storage has notifications enabled" do
      before do
        storage.update(health_notifications_enabled: true)
      end

      it "notifies admin users when the storage becomes healthy" do
        expect do
          health_service.healthy
        end.to have_enqueued_mail(Storages::StoragesMailer, :notify_healthy)
        .with(admin_user, storage, storage.health_reason).at_most(:once)
      end

      it "notifies admin users when the storage becomes unhealthy" do
        expect do
          health_service.unhealthy(reason: "thou_shall_not_pass_error")
        end.to have_enqueued_mail(Storages::StoragesMailer, :notify_unhealthy).with(admin_user, storage).at_most(:once)
      end
    end

    context "when the storage has notifications disabled" do
      before do
        storage.update(health_notifications_enabled: false)
      end

      it "does not notify admin users when the storage becomes healthy" do
        expect do
          health_service.healthy
        end.not_to have_enqueued_mail(Storages::StoragesMailer, :notify_healthy)
      end

      it "does not notify admin users when the storage becomes unhealthy" do
        expect do
          health_service.unhealthy(reason: "thou_shall_not_pass_error")
        end.not_to have_enqueued_mail(Storages::StoragesMailer, :notify_unhealthy)
      end
    end
  end
end
