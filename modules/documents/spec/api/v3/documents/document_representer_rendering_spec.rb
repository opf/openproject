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

RSpec.describe API::V3::Documents::DocumentRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:document) do
    build_stubbed(:document,
                  description: "Some description") do |document|
      allow(document)
        .to receive(:project)
        .and_return(workspace)
    end
  end
  let(:workspace) { build_stubbed(:project) }
  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { true }
  let(:representer) do
    described_class.create(document, current_user:, embed_links:)
  end
  let(:permissions) { all_permissions }
  let(:all_permissions) { %i(manage_documents) }

  subject { representer.to_json }

  describe "_links" do
    it_behaves_like "has a titled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.document document.id }
      let(:title) { document.title }
    end

    it_behaves_like "has an untitled link" do
      let(:link) { :attachments }
      let(:href) { api_v3_paths.attachments_by_document document.id }
    end

    it_behaves_like "has workspace linked"

    it_behaves_like "has an untitled action link" do
      let(:link) { :addAttachment }
      let(:href) { api_v3_paths.attachments_by_document document.id }
      let(:method) { :post }
      let(:permission) { :manage_documents }
    end

    it_behaves_like "has an untitled action link" do
      let(:link) { :update }
      let(:href) { api_v3_paths.document document.id }
      let(:method) { :patch }
      let(:permission) { :manage_documents }
    end

    context "when user is not allowed to edit documents" do
      it_behaves_like "has no link" do
        let(:link) { :update }
      end
    end

    describe "createCollaborationToken", with_settings: { real_time_text_collaboration_enabled: true } do
      let(:link) { :createCollaborationToken }
      let(:document_permissions) { %i(view_documents) }

      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_in_project(*document_permissions, project: workspace) if document_permissions.any?
        end
      end

      context "when the user may view documents" do
        it_behaves_like "has an untitled link" do
          let(:href) { api_v3_paths.document_collaboration_token document.id }
        end

        it "indicates the POST method" do
          expect(subject).to be_json_eql("post".to_json).at_path("_links/createCollaborationToken/method")
        end
      end

      context "when the user may manage documents" do
        let(:document_permissions) { %i(view_documents manage_documents) }

        it_behaves_like "has an untitled link" do
          let(:href) { api_v3_paths.document_collaboration_token document.id }
        end
      end

      context "when the user may not view documents" do
        let(:document_permissions) { [] }

        it_behaves_like "has no link"
      end

      context "when the user is anonymous, even though they may view documents" do
        let(:current_user) { build_stubbed(:anonymous) }

        it_behaves_like "has no link"
      end

      context "when the document is not collaborative" do
        let(:document) do
          build_stubbed(:document, kind: "classic") do |document|
            allow(document)
              .to receive(:project)
              .and_return(workspace)
          end
        end

        it_behaves_like "has no link"
      end

      context "when real-time collaboration is disabled",
              with_settings: { real_time_text_collaboration_enabled: false } do
        it_behaves_like "has no link"
      end

      context "when real-time collaboration is disabled after the representer has been cached" do
        it "no longer renders the link" do
          expect(described_class.create(document, current_user:, embed_links:).to_json)
            .to have_json_path("_links/createCollaborationToken")

          allow(Setting).to receive(:real_time_text_collaboration_enabled?).and_return(false)

          expect(described_class.create(document, current_user:, embed_links:).to_json)
            .not_to have_json_path("_links/createCollaborationToken")
        end
      end

      context "when rendered for a permitted user first and a user without permission afterwards" do
        let(:other_user) { build_stubbed(:user) }
        let(:permitted_representer) { described_class.create(document, current_user:, embed_links:) }
        let(:unpermitted_representer) { described_class.create(document, current_user: other_user, embed_links:) }

        before do
          mock_permissions_for(other_user, &:forbid_everything)
        end

        it "does not leak the link through the representer cache" do
          expect(permitted_representer.to_json).to have_json_path("_links/createCollaborationToken")

          # Make sure the second rendering is actually served from the cache filled by the first one.
          expect(unpermitted_representer.json_cache_key).to eq(permitted_representer.json_cache_key)
          expect(Rails.cache.exist?(OpenProject::Cache::CacheKey.key(permitted_representer.json_cache_key)))
            .to be(true)

          expect(unpermitted_representer.to_json).not_to have_json_path("_links/createCollaborationToken")
        end
      end
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Document" }
    end

    it_behaves_like "property", :id do
      let(:value) { document.id }
    end

    it_behaves_like "property", :title do
      let(:value) { document.title }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { document.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { document.updated_at }
      let(:json_path) { "updatedAt" }
    end

    it_behaves_like "API V3 formattable", "description" do
      let(:format) { "markdown" }
      let(:raw) { document.description }
      let(:html) { '<p class="op-uc-p">' + document.description + "</p>" }
    end
  end

  describe "_embedded" do
    it_behaves_like "has workspace embedded"
  end
end
