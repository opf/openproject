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

  describe "overallCosts" do
    context "has the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "overallCosts" }
        let(:type) { "String" }
        let(:name) { I18n.t("activerecord.attributes.work_package.overall_costs") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context "lacks the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path("overallCosts") }
    end
  end

  describe "laborCosts" do
    context "has the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "laborCosts" }
        let(:type) { "String" }
        let(:name) { I18n.t("activerecord.attributes.work_package.labor_costs") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context "lacks the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path("laborCosts") }
    end
  end

  describe "materialCosts" do
    context "has the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "materialCosts" }
        let(:type) { "String" }
        let(:name) { I18n.t("activerecord.attributes.work_package.material_costs") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context "lacks the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path("materialCosts") }
    end
  end

  describe "costsByType" do
    context "has the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "costsByType" }
        let(:type) { "Collection" }
        let(:name) { I18n.t("activerecord.attributes.work_package.spent_units") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    context "lacks the permissions" do
      before do
        allow(project)
          .to receive(:costs_enabled?)
          .and_return(false)
      end

      it { is_expected.not_to have_json_path("costsByType") }
    end
  end
end
