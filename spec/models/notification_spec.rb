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

require "spec_helper"

RSpec.describe Notification do
  describe "Associations" do
    it { is_expected.to belong_to(:journal) }
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:actor).class_name("User") }
    it { is_expected.to belong_to(:recipient).class_name("User") }

    it { is_expected.to have_one(:reminder_notification).dependent(:destroy) }
    it { is_expected.to have_one(:reminder).through(:reminder_notification) }
  end

  describe "Enums" do
    it do
      expect(subject).to define_enum_for(:reason)
        .with_values(
          mentioned: 0,
          assigned: 1,
          watched: 2,
          subscribed: 3,
          commented: 4,
          created: 5,
          processed: 6,
          prioritized: 7,
          scheduled: 8,
          responsible: 9,
          date_alert_start_date: 10,
          date_alert_due_date: 11,
          shared: 12,
          reminder: 13
        )
        .with_prefix
        .backed_by_column_of_type(:integer)
    end
  end

  describe ".save" do
    context "for a non existing journal (e.g. because it has been deleted)" do
      let(:notification) { build(:notification) }

      it "raises an error" do
        notification.journal_id = 99999
        expect { notification.save }
          .to raise_error ActiveRecord::InvalidForeignKey
      end
    end
  end

  describe "push scheduling", with_flag: { progressive_web_app: true }, with_settings: { web_push_enabled: true } do
    let(:recipient) { create(:user) }
    let(:work_package) { create(:work_package) }

    before { create(:push_subscription, user: recipient) }

    def create_notification(**)
      create(:notification, recipient:, resource: work_package, **)
    end

    it "enqueues the push job when an unread notification is created" do
      expect { create_notification(read_ian: false) }
        .to have_enqueued_job(PushSubscriptions::NotifyJob).with(recipient.id)
    end

    it "enqueues the push job when a read notification becomes unread" do
      notification = create_notification(read_ian: true)

      expect { notification.update!(read_ian: false) }
        .to have_enqueued_job(PushSubscriptions::NotifyJob).with(recipient.id)
    end

    it "does not enqueue when read_ian is nil" do
      expect { create_notification(read_ian: nil) }
        .not_to have_enqueued_job(PushSubscriptions::NotifyJob)
    end

    it "enqueues when a read notification is marked unread through the update service" do
      notification = create_notification(read_ian: true)

      expect { Notifications::UpdateService.new(user: recipient, model: notification, contract_class: EmptyContract).call(read_ian: false) }
        .to have_enqueued_job(PushSubscriptions::NotifyJob).with(recipient.id)
    end

    it "does not enqueue when an unread notification stays unread through the update service" do
      notification = create_notification(read_ian: false)
      clear_enqueued_jobs

      expect { Notifications::UpdateService.new(user: recipient, model: notification, contract_class: EmptyContract).call(read_ian: false) }
        .not_to have_enqueued_job(PushSubscriptions::NotifyJob)
    end

    it "does not enqueue on bulk updates because update_all skips callbacks" do
      notification = create_notification(read_ian: true)

      expect { described_class.where(id: notification.id).update_all(read_ian: false) }
        .not_to have_enqueued_job(PushSubscriptions::NotifyJob)
    end

    it "does not enqueue when the recipient has no subscription" do
      PushSubscription.delete_all

      expect { create_notification(read_ian: false) }
        .not_to have_enqueued_job(PushSubscriptions::NotifyJob)
    end
  end
end
