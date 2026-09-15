# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Wiki pages resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, public: false) }
  let(:wiki) { create(:wiki, project:) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:permissions) { %i[view_wiki_pages edit_wiki_pages manage_wiki view_wiki_edits] }
  let(:wiki_page) { create(:wiki_page, wiki:, title: "Start", text: "Initial text") }

  before { login_as user }

  describe "GET /api/v3/wiki_pages/:id" do
    it "renders the complete wiki page representation" do
      get api_v3_paths.wiki_page(wiki_page.id)

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to be_json_eql("WikiPage".to_json).at_path("_type")
      expect(last_response.body).to be_json_eql("Start".to_json).at_path("title")
      expect(last_response.body).to be_json_eql(api_v3_paths.wiki_page_form(wiki_page.id).to_json)
                                      .at_path("_links/update/href")
    end

    context "without view permission" do
      let(:permissions) { [] }

      it "returns not found" do
        get api_v3_paths.wiki_page(wiki_page.id)

        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v3/projects/:id/wiki_pages" do
    it "returns only pages from the project wiki" do
      wiki_page
      get api_v3_paths.wiki_pages_by_project(project.id)

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to be_json_eql(wiki_page.id.to_json).at_path("_embedded/elements/0/id")
    end
  end

  describe "POST /api/v3/wiki_pages" do
    it "creates a page in the linked project wiki" do
      wiki

      post api_v3_paths.wiki_pages,
           {
             title: "Created through API",
             text: { raw: "Content" },
             _links: { project: { href: api_v3_paths.project(project.id) } }
           }.to_json

      expect(last_response).to have_http_status(:created)
      expect(WikiPage.find_by(title: "Created through API")).to have_attributes(wiki: wiki, author: user)
    end
  end

  describe "PATCH and DELETE /api/v3/wiki_pages/:id" do
    it "updates the page with optimistic locking and deletes it" do
      previous_version = wiki_page.version

      patch api_v3_paths.wiki_page(wiki_page.id),
            { title: "Renamed", lockVersion: wiki_page.lock_version }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to be_json_eql((previous_version + 1).to_json).at_path("version")
      expect(wiki_page.reload.title).to eq("Renamed")

      delete api_v3_paths.wiki_page(wiki_page.id)

      expect(last_response).to have_http_status(:no_content)
      expect(WikiPage).not_to exist(wiki_page.id)
    end

    context "with descendants and no todo" do
      let!(:child) { create(:wiki_page, wiki:, parent: wiki_page) }

      it "returns an error requiring todo" do
        delete api_v3_paths.wiki_page(wiki_page.id)

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(WikiPage).to exist(wiki_page.id)
      end
    end

    context "without manage_wiki on delete" do
      let(:permissions) { %i[view_wiki_pages edit_wiki_pages] }

      it "is unauthorized" do
        delete api_v3_paths.wiki_page(wiki_page.id)

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(WikiPage).to exist(wiki_page.id)
      end
    end
  end

  describe "GET /api/v3/wiki_pages/:id/activities" do
    it "returns journals when permitted" do
      get api_v3_paths.wiki_page_activities(wiki_page.id)

      expect(last_response).to have_http_status(:ok)
    end

    context "without view_wiki_edits" do
      let(:permissions) { %i[view_wiki_pages] }

      it "is forbidden" do
        get api_v3_paths.wiki_page_activities(wiki_page.id)

        expect(last_response.status).to be_between(403, 404)
      end
    end
  end
end
