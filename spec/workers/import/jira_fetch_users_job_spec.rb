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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraFetchUsersJob do
  let(:job) { described_class.new }
  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:user_keys) { Set.new }

  describe "#collect_attachment_user_keys" do
    it "adds the author key of every attachment" do
      payload = {
        "attachment" => [
          { "filename" => "a.png", "author" => { "key" => "JIRAUSER100" } },
          { "filename" => "b.png", "author" => { "key" => "JIRAUSER200" } }
        ]
      }

      job.send(:collect_attachment_user_keys, user_keys, payload)
      expect(user_keys).to contain_exactly("JIRAUSER100", "JIRAUSER200")
    end

    it "does not add duplicates" do
      payload = {
        "attachment" => [
          { "filename" => "a.png", "author" => { "key" => "JIRAUSER100" } },
          { "filename" => "b.png", "author" => { "key" => "JIRAUSER100" } }
        ]
      }

      job.send(:collect_attachment_user_keys, user_keys, payload)
      expect(user_keys).to contain_exactly("JIRAUSER100")
    end

    it "skips attachments without an author" do
      payload = {
        "attachment" => [
          { "filename" => "a.png" },
          { "filename" => "b.png", "author" => nil },
          { "filename" => "c.png", "author" => { "key" => nil } },
          { "filename" => "d.png", "author" => { "key" => "JIRAUSER100" } }
        ]
      }

      job.send(:collect_attachment_user_keys, user_keys, payload)
      expect(user_keys).to contain_exactly("JIRAUSER100")
    end

    it "handles issues without attachments" do
      expect { job.send(:collect_attachment_user_keys, user_keys, {}) }.not_to raise_error
      expect(user_keys).to be_empty
    end
  end

  describe "#collect_user_keys_from_issue" do
    let(:mention_usernames) { Set.new }
    let(:issue) do
      instance_double(Import::JiraIssue, payload: {
                        "fields" => {
                          "description" => "no mentions here",
                          "creator" => { "key" => "JIRAUSER_CREATOR" },
                          "reporter" => { "key" => "JIRAUSER_REPORTER" },
                          "assignee" => { "key" => "JIRAUSER_ASSIGNEE" },
                          "comment" => {
                            "comments" => [{ "author" => { "key" => "JIRAUSER_COMMENTER" }, "body" => "a comment" }]
                          },
                          "attachment" => [
                            { "filename" => "a.png", "author" => { "key" => "JIRAUSER_UPLOADER" } }
                          ]
                        },
                        "changelog" => {
                          "histories" => [{ "author" => { "key" => "JIRAUSER_EDITOR" }, "items" => [] }]
                        }
                      })
    end

    it "collects attachment authors alongside the other involved users" do
      job.send(:collect_user_keys_from_issue, user_keys, mention_usernames, issue)

      expect(user_keys).to include("JIRAUSER_UPLOADER")
      expect(user_keys).to contain_exactly(
        "JIRAUSER_CREATOR",
        "JIRAUSER_REPORTER",
        "JIRAUSER_ASSIGNEE",
        "JIRAUSER_COMMENTER",
        "JIRAUSER_UPLOADER",
        "JIRAUSER_EDITOR"
      )
    end
  end

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

    context "when resolving a mentioned user fails with a non-404 error" do
      let(:api_error) { Import::JiraClient::ApiError.new("Boom", status: 500) }

      before do
        allow(jira_client).to receive(:user_by_username).with(username: "alice").and_raise(api_error)
      end

      it "raises an error" do
        expect { job.send(:resolve_mention_user_keys, %w[alice], user_keys, jira_client) }
          .to raise_error("Could not resolve mentioned user 'alice': Boom")
      end
    end
  end
end
