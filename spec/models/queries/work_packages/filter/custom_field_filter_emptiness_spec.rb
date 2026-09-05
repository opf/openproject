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

RSpec.describe Queries::WorkPackages::Filter::CustomFieldFilter,
               "filtering a text custom field on emptiness" do
  let(:query) { build_stubbed(:query, project:) }
  let(:instance) do
    described_class.create!(name: custom_field.column_name, operator:, values: [], context: query)
  end

  let(:project) { create(:project, types: [type], work_package_custom_fields: [custom_field]) }
  let(:type) { create(:type_task, custom_fields: [custom_field]) }

  let!(:wp_with_value) { create(:work_package, type:, project:, custom_values: { custom_field.id => "foo" }) }
  let!(:wp_blank) { create(:work_package, type:, project:, custom_values: { custom_field.id => "" }) }
  let!(:wp_nil) { create(:work_package, type:, project:, custom_values: { custom_field.id => nil }) }

  subject { WorkPackage.where(instance.where) }

  # A custom value keeps its value in a string column, so "no value" is stored as an empty
  # string as readily as NULL. Plain All would count the blank one as having a value.
  shared_examples "emptiness is expressible" do
    describe "has a value" do
      let(:operator) { "*" }

      it "returns only the work package that actually holds one" do
        expect(subject).to contain_exactly(wp_with_value)
      end
    end

    describe "is empty" do
      let(:operator) { "!*" }

      it "returns the blank and the unset one" do
        expect(subject).to contain_exactly(wp_blank, wp_nil)
      end
    end
  end

  context "with a long text custom field" do
    let(:custom_field) { create(:issue_custom_field, :text, name: "LongText") }

    it_behaves_like "emptiness is expressible"
  end

  context "with a single line string custom field" do
    let(:custom_field) { create(:issue_custom_field, :string, name: "ShortText") }

    it_behaves_like "emptiness is expressible"
  end
end
