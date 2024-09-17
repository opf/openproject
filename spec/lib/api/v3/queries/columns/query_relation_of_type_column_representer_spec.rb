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

RSpec.describe API::V3::Queries::Columns::QueryRelationOfTypeColumnRepresenter do
  include API::V3::Utilities::PathHelper

  let(:type) { { name: :label_relates_to, sym_name: :label_relates_to, order: 1, sym: :relation1 } }
  let(:column) { Queries::WorkPackages::Selects::RelationOfTypeSelect.new(type) }
  let(:representer) { described_class.new(column) }

  subject { representer.to_json }

  describe "generation" do
    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.query_column "relationsOfType#{type[:sym].to_s.camelcase}" }
        let(:title) { "#{I18n.t(type[:name]).capitalize} relations" }
      end
    end

    it "has _type QueryColumn::RelationOfType" do
      expect(subject)
        .to be_json_eql("QueryColumn::RelationOfType".to_json)
        .at_path("_type")
    end

    it "has id attribute" do
      expect(subject)
        .to be_json_eql("relationsOfType#{type[:sym].to_s.camelcase}".to_json)
        .at_path("id")
    end

    it "has relationType attribute" do
      expect(subject)
        .to be_json_eql(type[:sym].to_json)
        .at_path("relationType")
    end

    it "has name attribute" do
      expect(subject)
        .to be_json_eql("#{I18n.t(type[:name]).capitalize} relations".to_json)
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

    it "busts the cache on changes to the locale" do
      expect(representer)
        .to receive(:to_hash)

      I18n.with_locale(:de) do
        representer.to_json
      end
    end
  end
end
