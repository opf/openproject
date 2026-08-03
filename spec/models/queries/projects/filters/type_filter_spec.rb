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

RSpec.describe Queries::Projects::Filters::TypeFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :type_id }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :type_id }
    let(:values) { ["3"] }
    let(:admin) { build_stubbed(:admin) }
    let(:user) { build_stubbed(:user) }

    before do
      allow(Type).to receive(:pluck).with(:name, :id).and_return([["Foo", "1234"]])
    end

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expect(instance.allowed_values).to contain_exactly(["Foo", "1234"])
      end
    end
  end

  describe "filtering" do
    shared_let(:root_type) { create(:type, name: "Bug") }
    shared_let(:variant) { create(:type, name: "Mobile Bug", parent: root_type) }
    shared_let(:other_type) { create(:type, name: "Task") }

    shared_let(:project_with_root) { create(:project, types: [root_type]) }
    shared_let(:project_with_variant) { create(:project, types: [variant]) }
    shared_let(:project_with_other_type) { create(:project, types: [other_type]) }

    current_user { create(:admin) }

    def results_for(*types)
      ProjectQuery
        .new
        .tap { |query| query.where(:type_id, "=", types.map { |type| type.id.to_s }) }
        .results
    end

    it "finds projects running any member of the family of the filtered type" do
      expect(results_for(root_type)).to contain_exactly(project_with_root, project_with_variant)
      expect(results_for(variant)).to contain_exactly(project_with_root, project_with_variant)
    end

    it "keeps types of other families out" do
      expect(results_for(other_type)).to contain_exactly(project_with_other_type)
    end

    it "finds no projects for a type that does not exist" do
      query = ProjectQuery.new
      query.where(:type_id, "=", [(Type.maximum(:id) + 1).to_s])

      expect(query.results).to be_empty
    end
  end

  describe "#autocomplete_options" do
    shared_let(:root_type) { create(:type, name: "Bug") }
    shared_let(:variant) { create(:type, name: "Mobile Bug", parent: root_type) }

    subject(:options) { described_class.create!(name: :type_id, operator: "=", values:).autocomplete_options }

    context "with a root type selected" do
      let(:values) { [root_type.id.to_s] }

      it "offers roots only, variants being collapsed into them" do
        expect(options[:items]).to contain_exactly({ name: "Bug", id: root_type.id })
      end

      it "has the selected type as its model" do
        expect(options[:model]).to contain_exactly({ name: "Bug", id: root_type.id })
      end
    end

    context "with a variant selected" do
      let(:values) { [variant.id.to_s] }

      it "labels it with the name of its root" do
        expect(options[:model]).to contain_exactly({ name: "Bug", id: variant.id })
      end
    end
  end
end
