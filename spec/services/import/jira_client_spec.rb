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

RSpec.describe Import::JiraClient do
  subject(:client) { described_class.new(url:, personal_access_token:) }

  let(:url) { "https://jira.example.com" }
  let(:personal_access_token) { "test-token" }

  describe "#initialize" do
    context "when personal_access_token is nil" do
      let(:personal_access_token) { nil }

      it "raises ApiError" do
        expect { client }.to raise_error(Import::JiraClient::ApiError)
      end
    end
  end

  describe "SSRF protection" do
    context "when using a loopback address" do
      let(:url) { "http://127.0.0.1" }

      it "raises ConnectionError for API requests" do
        expect { client.server_info }
          .to raise_error(Import::JiraClient::ConnectionError)
      end

      it "raises ConnectionError for download_attachment" do
        expect { client.download_attachment("#{url}/attachment/123", "filename") }
          .to raise_error(Import::JiraClient::ConnectionError)
      end
    end

    context "when using a private network address (10.x.x.x)" do
      let(:url) { "http://10.0.0.1" }

      it "raises ConnectionError for API requests" do
        expect { client.projects }
          .to raise_error(Import::JiraClient::ConnectionError)
      end

      it "raises ConnectionError for download_attachment" do
        expect { client.download_attachment("#{url}/attachment/123", "filename") }
          .to raise_error(Import::JiraClient::ConnectionError)
      end
    end
  end
end
