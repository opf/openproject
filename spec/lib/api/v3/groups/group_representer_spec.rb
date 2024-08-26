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

RSpec.describe API::V3::Groups::GroupRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:group) do
    build_stubbed(:group).tap do |g|
      allow(g)
        .to receive(:users)
        .and_return(members)
    end
  end
  let(:current_user_admin) { false }
  let(:current_user) { build_stubbed(:user, admin: current_user_admin) }
  let(:representer) { described_class.new(group, current_user:, embed_links:) }
  let(:members) { 2.times.map { build_stubbed(:user) } }
  let(:permissions) { [:manage_members] }
  let(:embed_links) { true }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project: build_stubbed(:project)) # any project
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.group group.id }
        let(:title) { group.name }
      end
    end

    describe "members" do
      let(:link) { "members" }

      context "with the necessary permissions" do
        it_behaves_like "has a link collection" do
          let(:hrefs) do
            members.map do |member|
              {
                href: api_v3_paths.user(member.id),
                title: member.name
              }
            end
          end
        end
      end

      context "without the necessary permissions" do
        let(:permissions) { [] }

        it_behaves_like "has no link"
      end

      context "when first having the necessary permissions and then not (caching)" do
        before do
          representer.to_json
          # here the json will have links, afterwards we change the permissions

          mock_permissions_for(current_user, &:forbid_everything)
        end

        it_behaves_like "has no link"
      end
    end

    describe "updateImmediately" do
      let(:link) { "updateImmediately" }

      context "with the necessary permissions" do
        let(:current_user_admin) { true }

        it_behaves_like "has an untitled link" do
          let(:href) { api_v3_paths.group group.id }
        end
      end

      context "without the necessary permissions" do
        let(:current_user_admin) { false }

        it_behaves_like "has no link"
      end
    end

    describe "delete" do
      let(:link) { "delete" }

      context "with the necessary permissions" do
        let(:current_user_admin) { true }

        it_behaves_like "has an untitled link" do
          let(:href) { api_v3_paths.group group.id }
        end
      end

      context "without the necessary permissions" do
        let(:current_user_admin) { false }

        it_behaves_like "has no link"
      end
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Group" }
    end

    it_behaves_like "property", :id do
      let(:value) { group.id }
    end

    it_behaves_like "property", :name do
      let(:value) { group.name }
    end

    describe "createdAt" do
      context "without admin" do
        it "hides the createdAt property" do
          expect(subject).not_to have_json_path("createdAt")
        end
      end

      context "with an admin" do
        let(:current_user) { build_stubbed(:admin) }

        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { group.created_at }
          let(:json_path) { "createdAt" }
        end
      end
    end

    describe "updatedAt" do
      context "without admin" do
        it "hides the updatedAt property" do
          expect(subject).not_to have_json_path("updatedAt")
        end
      end

      context "with an admin" do
        let(:current_user) { build_stubbed(:admin) }

        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { group.updated_at }
          let(:json_path) { "updatedAt" }
        end
      end
    end
  end

  describe "_embedded" do
    describe "members" do
      let(:embedded_path) { "_embedded/members" }

      context "with the necessary permissions" do
        it "has an array of users embedded" do
          members.each_with_index do |user, index|
            expect(subject)
              .to be_json_eql("User".to_json)
              .at_path("#{embedded_path}/#{index}/_type")

            expect(subject)
              .to be_json_eql(user.name.to_json)
              .at_path("#{embedded_path}/#{index}/name")
          end
        end
      end

      context "without the necessary permissions" do
        let(:permissions) { [] }

        it "has no members embedded" do
          expect(subject)
            .not_to have_json_path embedded_path
        end
      end
    end
  end

  describe "caching" do
    let(:embed_links) { false }

    it "is based on the representer's cache_key" do
      expect(OpenProject::Cache)
        .to receive(:fetch)
        .with(representer.json_cache_key)
        .and_call_original

      representer.to_json
    end

    describe "#json_cache_key" do
      let!(:former_cache_key) { representer.json_cache_key }

      it "includes the name of the representer class" do
        expect(representer.json_cache_key)
          .to include("API", "V3", "Groups", "GroupRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the group is updated" do
        group.updated_at = Time.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
