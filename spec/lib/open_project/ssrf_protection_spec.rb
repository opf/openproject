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

RSpec.describe OpenProject::SsrfProtection do
  describe ".safe_ip?" do
    subject { described_class.safe_ip?(input) }

    context "with a public IPv4 string" do
      let(:input) { "1.1.1.1" }

      it "returns an IPAddr" do
        expect(subject).to eq IPAddr.new("1.1.1.1")
      end
    end

    context "with a loopback IPv4 string" do
      let(:input) { "127.0.0.1" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with a private network IPv4 string" do
      let(:input) { "10.0.0.1" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with a public IPv6 string" do
      let(:input) { "2606:4700:4700::1111" }

      it "returns an IPAddr" do
        expect(subject).to eq IPAddr.new("2606:4700:4700::1111")
      end
    end

    context "with a loopback IPv6 string" do
      let(:input) { "::1" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with a public IPAddr object" do
      let(:input) { IPAddr.new("1.1.1.1") }

      it "returns an IPAddr" do
        expect(subject).to eq IPAddr.new("1.1.1.1")
      end
    end

    context "with a private IPAddr object" do
      let(:input) { IPAddr.new("192.168.1.1") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with a hostname" do
      let(:input) { "example.com" }

      before do
        allow(described_class).to receive(:resolver).and_return(proc { resolved_addresses })
      end

      context "if it resolves to a public IP" do
        let(:resolved_addresses) { [IPAddr.new("93.184.216.34")] }

        it "returns the resolved IPAddr" do
          expect(subject).to eq IPAddr.new("93.184.216.34")
        end
      end

      context "if it resolves to a private IP" do
        let(:resolved_addresses) { [IPAddr.new("10.0.0.1")] }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "if it resolves to multiple IPs with both private and public" do
        let(:resolved_addresses) { [IPAddr.new("10.0.0.1"), IPAddr.new("1.2.3.4")] }

        it "returns the first public IPAddr" do
          expect(subject).to eq IPAddr.new("1.2.3.4")
        end
      end
    end

    context "with a private IP on the allowlist" do
      let(:input) { "127.0.0.1" }

      before do
        allow(OpenProject::Configuration)
          .to receive(:ssrf_protection_ip_allowlist)
          .and_return([IPAddr.new("127.0.0.1")])
      end

      it "returns a truthy value" do
        expect(subject).to eq IPAddr.new("127.0.0.1")
      end
    end
  end
end
