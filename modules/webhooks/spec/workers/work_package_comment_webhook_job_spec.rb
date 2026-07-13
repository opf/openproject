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

RSpec.describe WorkPackageCommentWebhookJob, :webmock, type: :model do
  include_context "with ssrf stubs"

  let(:user) { create(:admin) }
  let(:request_url) { "http://example.net/test/42" }
  let(:journal) { work_package.journals.last }
  let(:notes) { "Hello, I am a comment" }
  let(:work_package) { create(:work_package) }
  let(:webhook) { create(:webhook, all_projects: true, url: request_url, secret: nil) }

  let(:stubbed_url) { request_url }

  let(:request_headers) do
    { "Content-Type": "application/json", Accept: "application/json" }
  end

  let(:response_code) { 200 }
  let(:response_body) { "hook called" }
  let(:response_headers) do
    { content_type: "text/plain", x_spec: "foobar" }
  end

  let(:stub) do
    stub_request(:post, stubbed_url).with(
      body: hash_including(
        "action" => event_name,
        "activity" => hash_including(
          "_type" => "Activity::Comment",
          "comment" => hash_including("raw" => notes)
        )
      ),
      headers: request_headers.merge(host: "example.net")
    ).to_return(
      status: response_code,
      body: response_body,
      headers: response_headers
    )
  end

  let(:event_name) { "work_package_comment:comment" }

  subject(:job) { described_class.perform_now webhook.id, journal, event_name }

  before do
    journal.update!(notes:)
    allow(Webhooks::Webhook).to receive(:find).with(webhook.id).and_return(webhook)
    stub
  end

  it "requests the webhook" do
    subject
    expect(stub).to have_been_requested
  end

  it "creates a log for the call" do
    subject

    log = Webhooks::Log.last
    expect(log.webhook).to eq webhook
    expect(log.url).to eq webhook.url
    expect(log.event_name).to eq event_name
    expect(log.request_headers).to eq request_headers
    expect(log.response_code).to eq response_code
    expect(log.response_body).to eq response_body
    expect(log.response_headers).to eq response_headers
  end

  context "when the project does not match" do
    before do
      allow(webhook)
        .to receive(:enabled_for_project?).with(work_package.project_id)
        .and_return(false)
    end

    it "does not request the webhook" do
      subject
      expect(stub).not_to have_been_requested
    end
  end
end
