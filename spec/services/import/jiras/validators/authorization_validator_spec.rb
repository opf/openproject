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

RSpec.describe Import::Jiras::Validators::AuthorizationValidator, :webmock do
  include_context "with Jira connection stubs"

  subject(:results) { described_class.call(jira).results.map { [it.key, it.state, it.code].compact } }

  let(:jira) { build(:jira, url:) }

  def stub_permissions = stub_request(:get, "#{url}/rest/api/2/mypermissions")

  context "when the Jira user is an administrator" do
    it "passes every check" do
      expect(results).to eq([%i[credentials_accepted success], %i[administrator success]])
    end
  end

  context "when the Jira user is not an administrator" do
    let(:administrator) { false }

    it "fails the administrator check" do
      expect(results).to eq([%i[credentials_accepted success], %i[administrator failure not_administrator]])
    end
  end

  [401, 403].each do |status|
    context "when Jira rejects the credentials with #{status}" do
      before { stub_permissions.to_return(status:) }

      it "fails the credentials check and skips the administrator check" do
        expect(results).to eq([%i[credentials_accepted failure credentials_rejected], %i[administrator skipped]])
      end
    end
  end

  context "when Jira answers with something other than JSON" do
    before { stub_permissions.to_return(status: 200, body: "<html></html>") }

    it "fails the credentials check" do
      expect(results).to eq([%i[credentials_accepted failure invalid_response], %i[administrator skipped]])
    end
  end

  context "when Jira answers with a server error" do
    before { stub_permissions.to_return(status: 500) }

    it "fails the credentials check" do
      expect(described_class.call(jira)[:credentials_accepted])
        .to have_attributes(state: :failure, code: :api_error, context: { status: "500" })
    end
  end

  context "when Jira cannot be reached" do
    before { stub_permissions.to_raise(Errno::ECONNREFUSED) }

    it "fails the credentials check" do
      expect(results).to eq([%i[credentials_accepted failure unreachable], %i[administrator skipped]])
    end
  end
end
