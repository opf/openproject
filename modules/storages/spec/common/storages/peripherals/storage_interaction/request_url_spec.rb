# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::Peripherals::StorageInteraction::RequestUrl do
  describe "Builder" do
    context "if storage is of Nextcloud provider type" do
      context "with a standard host url" do
        let(:storage) { create(:nextcloud_storage, host: "https://example.com/") }

        it "returns the correct request URL" do
          expect(described_class::Builder.call(storage, "/path/")).to eq("https://example.com/path/")
          expect(described_class::Builder.call(storage, "/path")).to eq("https://example.com/path")
          expect(described_class::Builder.call(storage, "path/")).to eq("https://example.com/path/")
          expect(described_class::Builder.call(storage, "path")).to eq("https://example.com/path")

          expect(described_class::Builder.call(storage, "path", "/another/fragment/"))
            .to eq("https://example.com/path/another/fragment/")
          expect(described_class::Builder.call(storage, "/path/", "/another/fragment/"))
            .to eq("https://example.com/path/another/fragment/")
          expect(described_class::Builder.call(storage, "/path/", "another/fragment"))
            .to eq("https://example.com/path/another/fragment")
          expect(described_class::Builder.call(storage, "/path/", "/another/", "/fragment/"))
            .to eq("https://example.com/path/another/fragment/")
        end

        it "returns wrong request URLs if interface uses double slashes" do
          # so ... don't use them if you want good results ...
          expect(described_class::Builder.call(storage, "path", "//with-double-slash/"))
            .not_to eq("https://example.com/path//with-double-slash/")
        end
      end

      context "with a host url without a trailing slash (legacy)" do
        let(:storage) { create(:nextcloud_storage, host: "https://example.com") }

        it "returns the correct request URL" do
          expect(described_class::Builder.call(storage, "/path/")).to eq("https://example.com/path/")
          expect(described_class::Builder.call(storage, "path")).to eq("https://example.com/path")
        end
      end

      context "with a host url with path prefix" do
        let(:storage) { create(:nextcloud_storage, host: "https://example.com/html/") }

        it "returns the correct request URL" do
          expect(described_class::Builder.call(storage, "/path/")).to eq("https://example.com/html/path/")
          expect(described_class::Builder.call(storage, "path")).to eq("https://example.com/html/path")
        end
      end

      context "with a host url with path prefix and no trailing slash (legacy)" do
        let(:storage) { create(:nextcloud_storage, host: "https://example.com/html") }

        it "returns the correct request URL" do
          expect(described_class::Builder.call(storage, "/path/")).to eq("https://example.com/html/path/")
          expect(described_class::Builder.call(storage, "path")).to eq("https://example.com/html/path")
        end
      end
    end

    context "if storage is of OneDrive/SharePoint provider type" do
      let(:storage) { create(:one_drive_storage) }

      it "returns the correct request URL" do
        expect(described_class::Builder.call(storage, "/path/")).to eq("https://graph.microsoft.com/path/")
        expect(described_class::Builder.call(storage, "/path")).to eq("https://graph.microsoft.com/path")
        expect(described_class::Builder.call(storage, "path/")).to eq("https://graph.microsoft.com/path/")
        expect(described_class::Builder.call(storage, "path")).to eq("https://graph.microsoft.com/path")

        expect(described_class::Builder.call(storage, "path", "/to/", "/request"))
          .to eq("https://graph.microsoft.com/path/to/request")
      end
    end
  end
end
