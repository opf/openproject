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
require_module_spec_helper

RSpec.describe ITSM::OutboundEmails::SendConfirmationJob, type: :job do
  subject(:perform) { described_class.perform_now(thread) }

  let(:thread) { create(:itsm_email_thread) }
  let(:result) { ServiceResult.success(result: thread) }
  let(:service) { instance_double(ITSM::OutboundEmails::SendConfirmationService, call: result) }

  before { allow(ITSM::OutboundEmails::SendConfirmationService).to receive(:new).and_return(service) }

  it "sends the confirmation without trying again" do
    perform

    expect(service).to have_received(:call).with(thread:)
    expect(described_class).not_to have_been_enqueued
  end

  it "is queued like other notification emails" do
    expect(described_class.new(thread).priority).to eq(ApplicationJob.priority_number(:notification))
  end

  it "runs one confirmation per thread at a time" do
    expect(described_class.good_job_concurrency_config).to include(perform_limit: 1)
    expect(described_class.new(thread).good_job_concurrency_key).to eq("#{described_class.name}-#{thread.id}")
  end

  it "logs tagged with the thread" do
    allow(Rails.logger).to receive(:tagged).and_call_original

    perform

    expect(Rails.logger).to have_received(:tagged).with("ITSM", "email thread #{thread.id}")
  end

  context "when the email could not be sent" do
    let(:email_message) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", error_message: "421 Service not available")
    end
    let(:result) { ServiceResult.failure(result: email_message).tap { it.errors.add(:base, :delivery_failed) } }

    it "tries again later" do
      perform

      expect(described_class).to have_been_enqueued.with(thread)
    end

    it "fails with the reason and the server's answer" do
      expect { described_class.new.perform(thread) }
        .to raise_error(described_class::DeliveryFailed, "Confirmation not sent (delivery_failed): 421 Service not available")
    end

    it "gives up after the last attempt and logs it" do
      allow(Rails.logger).to receive(:warn)

      perform_enqueued_jobs { described_class.perform_later(thread) }

      expect(service).to have_received(:call).exactly(10).times
      expect(Rails.logger).to have_received(:warn) do |&message|
        expect(message.call).to eq("Confirmation for email thread #{thread.id} not sent after 10 attempts")
      end
    end
  end

  context "when the SMTP server could not be reached" do
    let(:result) { ServiceResult.failure(result: thread).tap { it.errors.add(:base, :unreachable) } }

    it "tries again later" do
      perform

      expect(described_class).to have_been_enqueued.with(thread)
    end
  end

  context "when the SMTP server rejected the email" do
    let(:email_message) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", error_message: "550 Mailbox unavailable")
    end
    let(:result) { ServiceResult.failure(result: email_message).tap { it.errors.add(:base, :delivery_rejected) } }
    let(:warned) { [] }

    before { allow(Rails.logger).to receive(:warn) { |&message| warned << message.call } }

    it "does not try again and logs the server's answer" do
      perform

      expect(described_class).not_to have_been_enqueued
      expect(warned).to include("Confirmation not sent (delivery_rejected): 550 Mailbox unavailable")
    end
  end

  context "when sending failed unexpectedly" do
    let(:email_message) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", error_message: "NoMethodError")
    end
    let(:result) { ServiceResult.failure(result: email_message).tap { it.errors.add(:base, :unexpected_error) } }
    let(:warned) { [] }

    before { allow(Rails.logger).to receive(:warn) { |&message| warned << message.call } }

    it "does not try again, as the error would come back" do
      perform

      expect(described_class).not_to have_been_enqueued
      expect(warned).to include("Confirmation not sent (unexpected_error): NoMethodError")
    end
  end

  context "when the instance's email limits stopped the email" do
    let(:result) { ServiceResult.failure(result: thread).tap { it.errors.add(:base, :not_delivered) } }

    it "does not try again" do
      perform

      expect(described_class).not_to have_been_enqueued
    end
  end

  context "when the project has no outgoing mailbox" do
    let(:result) { ServiceResult.failure(result: thread).tap { it.errors.add(:base, :no_outgoing_mailbox) } }
    let(:warned) { [] }

    before { allow(Rails.logger).to receive(:warn) { |&message| warned << message.call } }

    it "does not try again and logs why" do
      perform

      expect(described_class).not_to have_been_enqueued
      expect(warned).to include("Confirmation not sent (no_outgoing_mailbox)")
    end
  end

  context "when the thread cannot be found when the job runs" do
    before do
      described_class.perform_later(thread)
      thread.destroy
    end

    it "tries again later, as the thread may not be committed yet" do
      perform_enqueued_jobs

      expect(described_class).to have_been_enqueued
      expect(ITSM::OutboundEmails::SendConfirmationService).not_to have_received(:new)
    end
  end
end
