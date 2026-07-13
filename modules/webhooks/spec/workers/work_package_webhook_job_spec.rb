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

RSpec.describe WorkPackageWebhookJob, :webmock, type: :model do
  include_context "with ssrf stubs"

  shared_let(:user) { create(:admin) }
  shared_let(:title) { "Some workpackage subject" }
  shared_let(:request_url) { "http://example.net/test/42" }
  shared_let(:work_package) { create(:work_package, subject: title) }
  shared_let(:webhook) { create(:webhook, all_projects: true, url: request_url, secret: nil) }

  shared_examples "a work package webhook call" do
    let(:event) { "work_package:created" }
    let(:actor) { nil }
    let(:job) { described_class.perform_now webhook.id, work_package, event, actor: }

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
      stub_request(:post, stubbed_url)
        .with(
          body: hash_including(
            "action" => event,
            "work_package" => hash_including(
              "_type" => "WorkPackage",
              "subject" => title
            )
          ),
          headers: request_headers.merge(host: "example.net")
        )
        .to_return(
          status: response_code,
          body: response_body,
          headers: response_headers
        )
    end

    subject { job }

    before do
      allow(Webhooks::Webhook).to receive(:find).with(webhook.id).and_return(webhook)
      stub
    end

    it "requests with all projects" do
      expect(webhook)
        .to receive(:enabled_for_project?).with(work_package.project_id)
        .and_call_original

      subject
      expect(stub).to have_been_requested
    end

    it "does not request when project does not match" do
      expect(webhook)
        .to receive(:enabled_for_project?).with(work_package.project_id)
        .and_return(false)

      subject
      expect(stub).not_to have_been_requested
    end

    describe "successful flow" do
      before do
        subject
      end

      it "calls the webhook url" do
        expect(stub).to have_been_requested
      end

      it "creates a log for the call" do
        log = Webhooks::Log.last

        expect(log.webhook).to eq webhook
        expect(log.url).to eq webhook.url
        expect(log.event_name).to eq event
        expect(log.request_headers).to eq request_headers
        expect(log.response_code).to eq response_code
        expect(log.response_body).to eq response_body
        expect(log.response_headers).to eq response_headers
      end
    end
  end

  describe "triggering a work package update" do
    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:updated" }
    end
  end

  describe "triggering a work package creation" do
    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:created" }
    end
  end

  describe "triggering a work package update with an invalid url" do
    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:updated" }
      let(:response_code) { 404 }
      let(:response_body) { "not found" }
    end
  end

  describe "triggering a work package with an admin only custom field set on the embedded project Regression #62444" do
    shared_let(:project) { work_package.project }
    shared_let(:custom_field) do
      create(:project_custom_field, :string, admin_only: true, projects: [project])
    end
    shared_let(:custom_value) do
      create(:custom_value,
             custom_field:,
             customized: project,
             value: "wat")
    end

    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:created" }

      it "includes the custom field value" do
        subject

        expect(stub).to have_been_requested

        log = Webhooks::Log.last
        embedded_project = JSON.parse(log.request_body)["work_package"]["_embedded"]["project"]
        expect(embedded_project[custom_field.attribute_name(:camel_case)]).to eq "wat"
      end
    end
  end

  describe "actor field on updated event" do
    let(:author) { create(:user, firstname: "Original", lastname: "Author") }
    let(:updater) { create(:user, firstname: "Update", lastname: "User") }
    let(:work_package) { create(:work_package, author:, subject: title) }

    before do
      work_package.add_journal(user: updater, notes: "Updated the work package")
      work_package.save!
    end

    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:updated" }
      let(:actor) { updater }

      it "includes actor matching the journal user, not the work package author" do
        subject
        expect(stub).to have_been_requested

        log = Webhooks::Log.last
        payload = JSON.parse(log.request_body)

        expect(payload["actor"]["id"]).to eq updater.id
        expect(payload["actor"]["name"]).to eq updater.name
        expect(payload["actor"]["_type"]).to eq "User"
        expect(payload["actor"]["_links"]["self"]["href"]).to eq "/api/v3/users/#{updater.id}"

        # Author in the work package payload is still the original creator
        author_href = payload["work_package"]["_links"]["author"]["href"]
        expect(author_href).to include("/api/v3/users/#{author.id}")
      end
    end
  end

  describe "actor field on created event" do
    let(:creator) { create(:user, firstname: "Creator", lastname: "Person") }
    let(:work_package) { User.execute_as(creator) { create(:work_package, author: creator, subject: title) } }

    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:created" }
      let(:actor) { creator }

      it "includes actor matching the creator" do
        subject
        expect(stub).to have_been_requested

        log = Webhooks::Log.last
        payload = JSON.parse(log.request_body)

        expect(payload["actor"]["id"]).to eq creator.id
        expect(payload["actor"]["name"]).to eq creator.name
      end
    end
  end

  describe "actor absent when actor is nil" do
    it_behaves_like "a work package webhook call" do
      let(:event) { "work_package:updated" }
      let(:actor) { nil }

      it "fires the webhook without an actor key" do
        expect { subject }.not_to raise_error
        expect(stub).to have_been_requested

        log = Webhooks::Log.last
        payload = JSON.parse(log.request_body)
        expect(payload).not_to have_key("actor")
      end
    end
  end
end
