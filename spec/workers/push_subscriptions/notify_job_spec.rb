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

RSpec.describe PushSubscriptions::NotifyJob,
               with_flag: { progressive_web_app: true },
               with_settings: { web_push_enabled: true } do
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  let(:work_package) { create(:work_package, project:) }
  let!(:notification) { create(:notification, recipient: user, resource: work_package, read_ian: false) }
  let!(:subscriptions) { create_list(:push_subscription, 2, user:) }
  let(:response_code) { "201" }

  before do
    allow(OpenProject::SsrfProtection)
      .to receive(:post)
      .and_return(instance_double(Net::HTTPResponse, code: response_code))
  end

  def perform
    described_class.perform_now(user.id)
  end

  def expect_no_post
    expect(OpenProject::SsrfProtection).not_to have_received(:post)
  end

  describe ".schedule_for" do
    before { freeze_time }

    it "enqueues the job debounced" do
      described_class.schedule_for(user.id)

      expect(described_class).to have_been_enqueued.with(user.id).at(described_class::DEBOUNCE.from_now)
    end

    it "does nothing without subscriptions" do
      PushSubscription.delete_all

      described_class.schedule_for(user.id)

      expect(described_class).not_to have_been_enqueued.with(user.id)
    end

    it "does nothing when the user only has dormant subscriptions" do
      PushSubscription.update_all(session_id: nil)

      described_class.schedule_for(user.id)

      expect(described_class).not_to have_been_enqueued.with(user.id)
    end

    it "does nothing with the feature flag off", with_flag: { progressive_web_app: false } do
      described_class.schedule_for(user.id)

      expect(described_class).not_to have_been_enqueued.with(user.id)
    end

    it "limits concurrent enqueues to one per user" do
      expect(described_class.good_job_concurrency_config[:enqueue_limit]).to eq(1)
    end

    it "keys a retry apart from a fresh wake-up so a waiting retry does not block it" do
      fresh = described_class.new(user.id)
      retry_job = described_class.new(user.id, [1, 2], 2)

      expect(retry_job.good_job_concurrency_key).not_to eq(fresh.good_job_concurrency_key)
    end
  end

  describe "#perform" do
    it "posts once per subscription with the wake-up headers" do
      perform

      expect(OpenProject::SsrfProtection)
        .to have_received(:post)
        .with(a_string_starting_with("https://fcm.googleapis.com/"),
              headers: hash_including("Urgency" => "low",
                                      "Topic" => "openproject-unread",
                                      "Authorization" => a_string_starting_with("vapid t=")),
              body: nil,
              http_options: { open_timeout: 5, read_timeout: 10 })
        .twice
    end

    it "skips dormant subscriptions" do
      subscriptions.first.update_columns(session_id: nil)

      perform

      expect(OpenProject::SsrfProtection).to have_received(:post).once
    end

    it "sends the time-to-live header" do
      sent = []
      allow(OpenProject::SsrfProtection).to receive(:post) do |_endpoint, headers:, **|
        sent << headers.transform_keys(&:downcase)
        instance_double(Net::HTTPResponse, code: "201")
      end

      perform

      expect(sent.pluck("ttl")).to eq(%w[3600 3600])
    end

    it "touches the subscriptions on success" do
      subscriptions.each { it.update_columns(updated_at: 1.day.ago) }

      perform

      expect(subscriptions.map { it.reload.updated_at }).to all(be_within(1.minute).of(Time.current))
    end

    context "when the VAPID key is unreadable" do
      before do
        allow(OpenProject::WebPush).to receive(:vapid_key).and_raise(OpenProject::WebPush::UnreadableKey)
        allow(OpenProject.logger).to receive(:error)
      end

      it "logs once, posts nothing and keeps the subscriptions" do
        expect { perform }.not_to raise_error

        expect_no_post
        expect(OpenProject.logger).to have_received(:error).once
        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    context "with the setting off", with_settings: { web_push_enabled: false } do
      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    context "with a locked user" do
      before { user.locked! }

      it "deletes the subscriptions and posts nothing" do
        perform

        expect(PushSubscription.where(user_id: user.id)).to be_empty
        expect_no_post
      end
    end

    context "when reminders are paused today in the user's time zone" do
      before do
        today = Time.current.in_time_zone(user.time_zone).to_date
        user.pref.update!(pause_reminders: { enabled: true, first_day: today.to_s, last_day: today.to_s })
      end

      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    context "when the pause ended yesterday" do
      before do
        yesterday = Time.current.in_time_zone(user.time_zone).to_date - 1
        user.pref.update!(pause_reminders: { enabled: true, first_day: (yesterday - 3).to_s, last_day: yesterday.to_s })
      end

      it "posts" do
        perform

        expect(OpenProject::SsrfProtection).to have_received(:post).twice
      end
    end

    context "without unread notifications" do
      before { notification.update_columns(read_ian: true) }

      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    [404, 410].each do |code|
      context "when the push service answers #{code}" do
        let(:response_code) { code.to_s }

        it "destroys the subscriptions" do
          perform

          expect(PushSubscription.where(user_id: user.id)).to be_empty
        end
      end
    end

    context "when the push service answers 401" do
      let(:response_code) { "401" }

      it "keeps the subscriptions and logs the vendor host without the endpoint" do
        allow(Rails.logger).to receive(:warn)

        expect { perform }.not_to have_enqueued_job(described_class)

        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
        expect(Rails.logger).to have_received(:warn).with(a_string_including("fcm.googleapis.com", "401")).twice
        expect(Rails.logger).not_to have_received(:warn).with(a_string_including(subscriptions.first.endpoint))
      end
    end

    [429, 503].each do |code|
      context "when the push service answers #{code} for one subscription" do
        let(:failing) { subscriptions.first }
        let(:healthy) { subscriptions.second }

        before do
          failing.update_columns(endpoint: "https://fcm.googleapis.com/failing")
          healthy.update_columns(endpoint: "https://fcm.googleapis.com/ok", updated_at: 1.day.ago)
          allow(OpenProject::SsrfProtection).to receive(:post) do |endpoint, **|
            instance_double(Net::HTTPResponse, code: endpoint.end_with?("/failing") ? code.to_s : "201")
          end
        end

        it "retries only the failing subscription with the next attempt number" do
          expect { perform }
            .to have_enqueued_job(described_class).with(user.id, [failing.id], 2)

          expect(healthy.reload.updated_at).to be_within(1.minute).of(Time.current)
          expect(PushSubscription.where(user_id: user.id).count).to eq(2)
        end

        it "schedules the retry with the polynomial backoff and jitter" do
          freeze_time do
            perform

            scheduled_at = ActiveJob::Base.queue_adapter.enqueued_jobs.last[:at]
            expect(scheduled_at).to be_between(3.seconds.from_now.to_f, 3.15.seconds.from_now.to_f)
          end
        end
      end
    end

    context "when performing a retry" do
      def perform_retry(subscription_ids, attempt)
        described_class.perform_now(user.id, subscription_ids, attempt)
      end

      it "posts only to the given subscriptions" do
        perform_retry([subscriptions.first.id], 2)

        expect(OpenProject::SsrfProtection).to have_received(:post).once
      end

      it "still posts nothing without unread notifications" do
        notification.update_columns(read_ian: true)

        perform_retry([subscriptions.first.id], 2)

        expect_no_post
      end

      context "when the last attempt fails" do
        let(:response_code) { "503" }

        before { allow(Rails.logger).to receive(:warn) }

        it "logs that it gives up and does not enqueue again" do
          expect { perform_retry(subscriptions.map(&:id), described_class::MAX_ATTEMPTS) }
            .not_to have_enqueued_job(described_class)

          expect(Rails.logger).to have_received(:warn).with(a_string_matching(/giving up/i))
        end
      end
    end

    context "when the subscriptions have mixed outcomes" do
      let(:first_subscription) { subscriptions.first }
      let(:second_subscription) { subscriptions.second }

      before do
        first_subscription.update_columns(endpoint: "https://fcm.googleapis.com/gone")
        second_subscription.update_columns(endpoint: "https://fcm.googleapis.com/ok", updated_at: 1.day.ago)
        allow(OpenProject::SsrfProtection).to receive(:post) do |endpoint, **|
          instance_double(Net::HTTPResponse, code: endpoint.end_with?("/gone") ? "410" : "201")
        end
      end

      it "destroys the gone one, touches the other and does not retry" do
        expect { perform }.not_to have_enqueued_job(described_class)

        expect(PushSubscription.exists?(first_subscription.id)).to be(false)
        expect(second_subscription.reload.updated_at).to be_within(1.minute).of(Time.current)
      end
    end

    context "when the first subscription's connection is refused" do
      before do
        calls = 0
        allow(OpenProject::SsrfProtection).to receive(:post) do
          calls += 1
          raise Errno::ECONNREFUSED if calls == 1

          instance_double(Net::HTTPResponse, code: "201")
        end
      end

      it "still posts to the second subscription and schedules a retry" do
        expect { perform }.to have_enqueued_job(described_class).with(user.id, [a_kind_of(Integer)], 2)

        expect(OpenProject::SsrfProtection).to have_received(:post).twice
        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end

    context "when the recipient cannot see the notification's work package" do
      let(:other_project) { create(:project) }
      let(:work_package) { create(:work_package, project: other_project) }

      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    context "when every notification was read before the job ran" do
      before { Notification.where(recipient: user).update_all(read_ian: true) }

      it "posts nothing" do
        perform

        expect_no_post
      end
    end

    context "when the endpoint resolves to a private address" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:post).and_raise(SsrfFilter::PrivateIPAddress)
      end

      it "logs the subscription id and error class without the endpoint" do
        allow(Rails.logger).to receive(:warn)

        perform

        subscriptions.each do |subscription|
          expect(Rails.logger)
            .to have_received(:warn)
            .with("Push subscription #{subscription.id} rejected: SsrfFilter::PrivateIPAddress")
        end
      end

      it "keeps the subscriptions and does not retry" do
        expect { perform }.not_to have_enqueued_job(described_class)

        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end

    context "when the endpoint hostname cannot be resolved" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:post).and_raise(SsrfFilter::UnresolvedHostname)
      end

      it "schedules a retry and keeps the subscriptions" do
        expect { perform }
          .to have_enqueued_job(described_class).with(user.id, subscriptions.map(&:id), 2)

        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end

    context "when the request times out" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:post).and_raise(Net::ReadTimeout)
      end

      it "schedules a retry and keeps the subscriptions" do
        expect { perform }
          .to have_enqueued_job(described_class).with(user.id, subscriptions.map(&:id), 2)

        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end

    context "when the push service sends a malformed response" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:post).and_raise(Net::HTTPBadResponse)
      end

      it "retries every subscription instead of aborting the loop" do
        expect { perform }
          .to have_enqueued_job(described_class).with(user.id, subscriptions.map(&:id), 2)
      end
    end

    context "when the push service answers with an unexpected code" do
      let(:response_code) { "302" }

      it "logs and keeps the subscriptions" do
        allow(Rails.logger).to receive(:warn)

        perform

        expect(Rails.logger).to have_received(:warn).twice
        expect(PushSubscription.where(user_id: user.id).count).to eq(2)
      end
    end
  end
end
