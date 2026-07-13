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

RSpec.describe Webhooks::Outgoing::RequestWebhookService, :webmock, type: :model do
  include_context "with ssrf stubs"

  let(:user) { build_stubbed(:user) }
  let(:instance) { described_class.new(webhook, event_name: :created, current_user: user) }

  shared_let(:webhook) { create(:webhook, all_projects: true, url: "https://example.net/test/42", secret: nil) }

  subject { instance.call!(body: "body", headers: {}) }

  describe "#call!" do
    context "when the request is successful" do
      before do
        stub_request(:post, webhook.url)
          .with(body: "body", headers: { "X-Custom" => "header" })
          .to_return(status: 200, body: "OK", headers: { "Content-Type" => "application/json" })
      end

      subject { instance.call!(body: "body", headers: { "X-Custom" => "header" }) }

      it "makes a POST request to the webhook URL with the given body and headers" do
        subject
        expect(WebMock).to have_requested(:post, webhook.url)
          .with(body: "body", headers: { "X-Custom" => "header", "Host" => "example.net" }).once
      end

      it "creates a log entry" do
        expect { subject }.to change(Webhooks::Log, :count).by(1)
      end

      it "logs the response code, body, and URL" do
        subject
        log = Webhooks::Log.last
        expect(log.response_code).to eq(200)
        expect(log.response_body).to eq("OK")
        expect(log.url).to eq(webhook.url)
      end

      it "connects to the original hostname while routing through the resolved safe IP address" do
        http_start_args = nil
        allow(Net::HTTP).to receive(:start).and_wrap_original do |original, *args, **kwargs, &block|
          http_start_args = { host: args[0], options: kwargs }
          original.call(*args, **kwargs, &block)
        end

        subject

        expect(http_start_args[:host]).to eq("example.net")
        expect(http_start_args[:options]).to include(ipaddr: WithSsrfStubsMixin::SSRF_TEST_IP)
      end
    end

    context "when the request times out" do
      before do
        stub_request(:post, webhook.url).to_timeout
      end

      it "re-raises the timeout error while still creating a log entry" do
        expect { subject }.to raise_error(Net::OpenTimeout)

        expect(Webhooks::Log.count).to eq(1)
      end
    end

    context "when request_url fails with SSL errors" do
      before do
        stub_request(:post, webhook.url).to_raise(OpenSSL::SSL::SSLError)
      end

      it "still logs the exception" do
        expect { subject }.to change(Webhooks::Log, :count).by(1)
      end
    end

    context "when the webhook URL points to a private IP" do
      let(:instance) { described_class.new(private_webhook, event_name: :created, current_user: user) }
      let(:private_webhook) { create(:webhook, all_projects: true, url: "http://192.168.1.1/hook", secret: nil) }

      subject { instance.call!(body: "body", headers: {}) }

      it "creates a log entry" do
        expect { subject }.to change(Webhooks::Log, :count).by(1)
      end

      it "logs response_code -1 and an error message indicating the IP is private" do
        subject
        log = Webhooks::Log.last
        expect(log.response_code).to eq(-1)
        expect(log.response_body).to include("192.168.1.1")
        expect(log.response_body).to include("OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST")
      end
    end

    context "when the webhook URL points to a private IP that is on the allowlist",
            with_ssrf_ip_allowlist: %w[192.168.1.1] do
      let(:instance) { described_class.new(private_webhook, event_name: :created, current_user: user) }
      let(:private_webhook) { create(:webhook, all_projects: true, url: "http://192.168.1.1/hook", secret: nil) }

      before do
        stub_request(:post, "http://192.168.1.1/hook")
          .to_return(status: 200, body: "OK")
      end

      subject { instance.call!(body: "body", headers: {}) }

      it "creates a log entry" do
        expect { subject }.to change(Webhooks::Log, :count).by(1)
      end

      it "logs response_code 200, indicating the request succeeded" do
        subject
        log = Webhooks::Log.last
        expect(log.response_code).to eq(200)
      end
    end

    context "when an unexpected error occurs" do
      before do
        stub_request(:post, webhook.url).to_raise(StandardError.new("something went wrong"))
      end

      it "creates a log entry" do
        expect { subject }.to change(Webhooks::Log, :count).by(1)
      end

      it "logs response_code -1 and the error message as the response body" do
        subject
        log = Webhooks::Log.last
        expect(log.response_code).to eq(-1)
        expect(log.response_body).to eq("something went wrong")
      end
    end
  end
end
