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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter do
  let(:custom_field) { build(:custom_field) }
  let(:schema) do
    API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:)
  end
  let(:embedded) { false }
  let(:representer) do
    described_class.create(schema,
                           self_link: nil,
                           form_embedded: embedded,
                           current_user:)
  end
  let(:project) { work_package.project }
  let(:work_package) { build_stubbed(:work_package) }
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project :edit_work_packages, project: work_package.project
    end

    login_as(current_user)
  end

  subject { representer.to_json }

  shared_examples_for "a cost schema property" do |json_path|
    context "with costs enabled and a cost type available" do
      before do
        allow(project).to receive_messages(costs_enabled?: true, cost_types_available?: true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { json_path }
      end
    end

    context "when costs are disabled" do
      before do
        allow(project).to receive_messages(costs_enabled?: false, cost_types_available?: true)
      end

      it { is_expected.not_to have_json_path(json_path) }
    end
  end

  shared_examples_for "hidden without a cost type" do |json_path|
    context "when no cost type is available" do
      before do
        allow(project).to receive_messages(costs_enabled?: true, cost_types_available?: false)
      end

      it { is_expected.not_to have_json_path(json_path) }
    end
  end

  shared_examples_for "shown without a cost type" do |json_path|
    context "when no cost type is available" do
      before do
        allow(project).to receive_messages(costs_enabled?: true, cost_types_available?: false)
      end

      it { is_expected.to have_json_path(json_path) }
    end
  end

  describe "overallCosts" do
    it_behaves_like "a cost schema property", "overallCosts" do
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.overall_costs") }
      let(:required) { false }
      let(:writable) { false }
    end

    it_behaves_like "hidden without a cost type", "overallCosts"
  end

  describe "laborCosts" do
    it_behaves_like "a cost schema property", "laborCosts" do
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.labor_costs") }
      let(:required) { false }
      let(:writable) { false }
    end

    it_behaves_like "shown without a cost type", "laborCosts"
  end

  describe "materialCosts" do
    it_behaves_like "a cost schema property", "materialCosts" do
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.material_costs") }
      let(:required) { false }
      let(:writable) { false }
    end

    it_behaves_like "hidden without a cost type", "materialCosts"
  end

  describe "costsByType" do
    it_behaves_like "a cost schema property", "costsByType" do
      let(:type) { "Collection" }
      let(:name) { I18n.t("activerecord.attributes.work_package.spent_units") }
      let(:required) { false }
      let(:writable) { false }
    end

    it_behaves_like "hidden without a cost type", "costsByType"
  end
end
