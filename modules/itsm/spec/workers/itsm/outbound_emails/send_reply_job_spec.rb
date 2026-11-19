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

RSpec.describe ITSM::OutboundEmails::SendReplyJob, type: :job do
  subject(:perform) { described_class.perform_now(journal) }

  let(:journal) { create(:work_package_journal, notes: "We replaced the toner.", version: 2) }
  let(:available) { true }
  let(:availability) { instance_double(ITSM::OutboundEmails::ReplyAvailability, available?: available) }
  let(:result) { ServiceResult.success(result: journal) }
  let(:service) { instance_double(ITSM::OutboundEmails::SendReplyService, call: result) }
  let(:warned) { [] }

  before do
    allow(ITSM::OutboundEmails::ReplyAvailability)
      .to receive(:new).with(work_package: journal.journable, user: journal.user).and_return(availability)
    allow(ITSM::OutboundEmails::SendReplyService).to receive(:new).and_return(service)
    allow(Rails.logger).to receive(:warn) { |&message| warned << message.call }
  end

  it "sends the reply without trying again" do
    perform

    expect(service).to have_received(:call).with(journal:)
    expect(described_class).not_to have_been_enqueued
  end

  it "is queued like other notification emails and runs one reply per comment at a time" do
    job = described_class.new(journal)

    expect(job.priority).to eq(ApplicationJob.priority_number(:notification))
    expect(described_class.good_job_concurrency_config).to include(perform_limit: 1)
    expect(job.good_job_concurrency_key).to eq("#{described_class.name}-#{journal.id}")
  end

  context "when replying is no longer available" do
    let(:available) { false }

    it "sends nothing" do
      perform

      expect(ITSM::OutboundEmails::SendReplyService).not_to have_received(:new)
    end
  end

  context "when the email could not be sent" do
    let(:email_message) do
      create(:itsm_email_message, journal:, direction: "outbound", status: "failed", error_message: "421 Service not available")
    end
    let(:result) { ServiceResult.failure(result: email_message).tap { it.errors.add(:base, :delivery_failed) } }

    it "tries again later" do
      perform

      expect(described_class).to have_been_enqueued.with(journal)
    end

    it "fails with the reason and the server's answer" do
      expect { described_class.new.perform(journal) }
        .to raise_error(described_class::DeliveryFailed, "Reply not sent (delivery_failed): 421 Service not available")
    end

    it "gives up after the last attempt and logs it" do
      perform_enqueued_jobs { described_class.perform_later(journal) }

      expect(service).to have_received(:call).exactly(10).times
      expect(warned).to include("Reply for comment #{journal.id} not sent after 10 attempts")
    end
  end

  context "when the SMTP server could not be reached" do
    let(:result) { ServiceResult.failure(result: journal).tap { it.errors.add(:base, :unreachable) } }

    it "tries again later" do
      perform

      expect(described_class).to have_been_enqueued.with(journal)
    end
  end

  context "when the SMTP server rejected the email" do
    let(:email_message) do
      create(:itsm_email_message, journal:, direction: "outbound", status: "failed", error_message: "550 Mailbox unavailable")
    end
    let(:result) { ServiceResult.failure(result: email_message).tap { it.errors.add(:base, :delivery_rejected) } }

    it "does not try again and logs the server's answer" do
      perform

      expect(described_class).not_to have_been_enqueued
      expect(warned).to include("Reply not sent (delivery_rejected): 550 Mailbox unavailable")
    end
  end

  context "when the comment was deleted before the job ran" do
    before do
      described_class.perform_later(journal)
      journal.destroy
    end

    it "drops the job" do
      expect { perform_enqueued_jobs }.not_to raise_error
      expect(ITSM::OutboundEmails::SendReplyService).not_to have_received(:new)
    end
  end
end
