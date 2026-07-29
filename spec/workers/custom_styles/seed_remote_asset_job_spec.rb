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
      perform

      expect(custom_style.reload.logo.file).to be_present
      expect(custom_style.logo.file.content_type).to eq "image/png"
      expect(custom_style.logo.file.filename).to eq "logo.png"
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

    it "retries the job" do
      expect { perform }.to have_enqueued_job(described_class)
      expect(custom_style.reload.logo.file).to be_nil
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

    context "when the IP address is on the SSRF allowlist", with_ssrf_ip_allowlist: %w[127.0.0.1] do
      it "stores the asset on the custom style" do
        Timeout.timeout(10) { perform }

        expect(custom_style.reload.logo.file).to be_present
        expect(custom_style.logo.file.content_type).to eq "image/png"
      end
    end
  end
end
