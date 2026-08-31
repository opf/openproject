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
require "webrick"

RSpec.describe CustomStyles::SeedRemoteAssetJob do
  let(:custom_style) { CustomStyle.create! }
  let(:url) { "https://example.com/image.png" }

  subject(:perform) { described_class.perform_now(custom_style, :logo, url) }

  context "with a downloadable asset", :webmock do
    before do
      stub_request(:get, url)
        .to_return(status: 200, body: Rails.root.join("spec/fixtures/files/image.png").read)
    end

    it "stores it on the custom style" do
      allow(Rails.logger).to receive(:info)

      perform

      expect(custom_style.reload.logo.file).to be_present
      expect(custom_style.logo.file.content_type).to eq "image/png"
      expect(custom_style.logo.file.filename).to eq "logo.png"
      expect(Rails.logger).to have_received(:info).with("Seeded design asset 'logo' from #{url}.")
    end

    it "stores the file even when invoked inside an open transaction" do
      # Mimics RootSeeder: CarrierWave only uploads in after_commit, and Rails
      # drops after_commit on earlier instances of the same row in a transaction.
      CustomStyle.transaction do
        described_class.perform_now(custom_style, :favicon, url)
        described_class.perform_now(custom_style, :logo, url)
      end

      custom_style.reload
      expect(custom_style.favicon).to be_readable
      expect(custom_style.logo).to be_readable
    end

    context "when it is an svg" do
      let(:url) { "https://example.com/image.svg" }

      before do
        stub_request(:get, url)
          .to_return(status: 200, body: Rails.root.join("spec/fixtures/files/icon_logo.svg").read)
      end

      it "detects the content type and extension" do
        perform

        expect(custom_style.reload.logo.file.content_type).to eq "image/svg+xml"
        expect(custom_style.logo.file.filename).to eq "logo.svg"
      end
    end
  end

  context "when the asset is not available", :webmock do
    before do
      stub_request(:get, url).to_return(status: 404)
    end

    it "logs the failed attempt and reschedules itself" do
      allow(Rails.logger).to receive(:error)

      expect { perform }.not_to raise_error

      expect(described_class).to have_been_enqueued.with(custom_style, :logo, url)
      expect(custom_style.reload.logo.file).to be_nil
      expect(Rails.logger)
        .to have_received(:error)
        .with(a_string_starting_with("Failed to seed design asset 'logo' from #{url} on attempt 1: HTTP Error: 404"))
    end

    it "discards and logs after retries are exhausted" do
      allow(Rails.logger).to receive(:error)

      job = described_class.new(custom_style, :logo, url)
      allow(job).to receive_messages(executions: 5, executions_for: 5)

      expect { job.perform_now }.not_to raise_error
      expect(described_class).not_to have_been_enqueued
      expect(Rails.logger)
        .to have_received(:error)
        .with(a_string_starting_with("Discarding design asset seed for 'logo' from #{url} after 5 attempt(s): HTTP Error: 404"))
    end
  end

  # Served by a real server, as WebMock would intercept the request before the SSRF filter kicks in
  context "when the asset is served from a private IP address" do
    let(:server) do
      WEBrick::HTTPServer.new(Port: 0,
                              BindAddress: "127.0.0.1",
                              Logger: WEBrick::Log.new(StringIO.new),
                              AccessLog: [])
    end
    let(:url) { "http://127.0.0.1:#{server.listeners[0].addr[1]}/image.png" }

    before do
      server.mount_proc "/image.png" do |_request, response|
        response.body = Rails.root.join("spec/fixtures/files/image.png").read
      end

      Thread.new { server.start }
    end

    after do
      server.shutdown
    end

    it "discards the job without downloading" do
      expect { perform }.not_to have_enqueued_job(described_class)
      expect(custom_style.reload.logo.file).to be_nil
    end

    it "logs why it was blocked and that the job is discarded" do
      allow(Rails.logger).to receive(:error)

      perform

      expect(Rails.logger)
        .to have_received(:error)
        .with(a_string_including("resolves only to private IP addresses",
                                 "OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST"))
      expect(Rails.logger)
        .to have_received(:error)
        .with(a_string_starting_with("Discarding design asset seed for 'logo' from #{url} after"))
    end

    context "when the IP address is on the SSRF allowlist", with_ssrf_ip_allowlist: %w[127.0.0.1] do
      it "stores the asset on the custom style" do
        Timeout.timeout(10) { perform }

        expect(custom_style.reload.logo.file).to be_present
        expect(custom_style.logo.file.content_type).to eq "image/png"
      end
    end
  end
end
