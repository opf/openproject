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

RSpec.describe API::V3::Queries::Columns::QueryRelationToTypeColumnRepresenter do
  include API::V3::Utilities::PathHelper

  let(:type) { build_stubbed(:type) }
  let(:column) { Queries::WorkPackages::Selects::RelationToTypeSelect.new(type) }
  let(:representer) { described_class.new(column) }

  subject { representer.to_json }

  describe "generation" do
    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.query_column "relationsToType#{type.id}" }
        let(:title) { "Relations to #{type.name}" }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "type" }
        let(:href) { api_v3_paths.type type.id }
        let(:title) { type.name }
      end

      it "lists the type it counts relations to" do
        expect(subject)
          .to be_json_eql([{ href: api_v3_paths.type(type.id), title: type.name }].to_json)
          .at_path("_links/types")
      end

      # The client counts a relation by comparing the target's type against these, and a
      # work package carries whichever member of the family its project runs.
      context "when the type has variants", with_flag: { type_variants: true } do
        let(:type) { create(:type, name: "Bug") }
        let!(:variant) { create(:type, name: "Mobile Bug", parent: type) }

        it "lists every member of the family, all named after the root" do
          expect(subject)
            .to be_json_eql([{ href: api_v3_paths.type(type.id), title: "Bug" },
                             { href: api_v3_paths.type(variant.id), title: "Bug" }].to_json)
            .at_path("_links/types")
        end
      end
    end

    it "has _type QueryColumn::RelationToType" do
      expect(subject)
        .to be_json_eql("QueryColumn::RelationToType".to_json)
        .at_path("_type")
    end

    it "has id attribute" do
      expect(subject)
        .to be_json_eql("relationsToType#{type.id}".to_json)
        .at_path("id")
    end

    it "has name attribute" do
      expect(subject)
        .to be_json_eql("Relations to #{type.name}".to_json)
        .at_path("name")
    end
  end

  describe "caching" do
    before do
      # fill the cache
      representer.to_json
    end

    it "is cached" do
      expect(representer)
        .not_to receive(:to_hash)

      representer.to_json
    end

    it "busts the cache on changes to the name" do
      allow(column)
        .to receive(:name)
        .and_return("blubs")

      expect(representer)
        .to receive(:to_hash)

      representer.to_json
    end

    it "busts the cache on changes to the type" do
      allow(type)
        .to receive(:cache_key)
        .and_return("a_different_one")

      expect(representer)
        .to receive(:to_hash)

      representer.to_json
    end

    it "busts the cache on changes to the locale" do
      expect(representer)
        .to receive(:to_hash)

      I18n.with_locale(:de) do
        representer.to_json
      end
    end
  end

  describe "#json_cache_key", with_flag: { type_variants: true } do
    let(:type) { create(:type) }
    let!(:variant) { create(:type, parent: type) }

    # A family gaining a variant changes what the column counts without touching the type
    # it is named after.
    it "keys on every member of the family" do
      expect(representer.json_cache_key)
        .to include(type.cache_key_with_version, variant.cache_key_with_version)
    end
  end
end
