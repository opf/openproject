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

RSpec.describe Import::JiraFetchAndImportProjectsJob do
  let(:job) { described_class.new }
  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:user_keys) { Set.new }

  describe "#resolve_mention_user_keys" do
    context "when all mentioned users exist" do
      before do
        allow(jira_client).to receive(:user_by_username).with(username: "alice").and_return({ "key" => "JIRAUSER100" })
        allow(jira_client).to receive(:user_by_username).with(username: "bob").and_return({ "key" => "JIRAUSER200" })
      end

      it "adds all user keys" do
        job.send(:resolve_mention_user_keys, %w[alice bob], user_keys, jira_client)
        expect(user_keys).to contain_exactly("JIRAUSER100", "JIRAUSER200")
      end
    end

    context "when a mentioned user does not exist in Jira" do
      let(:api_error) { Import::JiraClient::ApiError.new("User not found", status: 404) }

      before do
        allow(jira_client).to receive(:user_by_username).with(username: "alice").and_return({ "key" => "JIRAUSER100" })
        allow(jira_client).to receive(:user_by_username).with(username: "ghost").and_raise(api_error)
      end

      it "does not raise an error" do
        expect { job.send(:resolve_mention_user_keys, %w[alice ghost], user_keys, jira_client) }.not_to raise_error
      end

      it "skips the missing user and still adds the existing one" do
        job.send(:resolve_mention_user_keys, %w[alice ghost], user_keys, jira_client)
        expect(user_keys).to contain_exactly("JIRAUSER100")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        job.send(:resolve_mention_user_keys, %w[alice ghost], user_keys, jira_client)
        expect(Rails.logger).to have_received(:info).with(a_string_including("ghost"))
      end
    end
  end
end
