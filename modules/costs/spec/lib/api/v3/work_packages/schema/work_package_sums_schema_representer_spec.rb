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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSumsSchemaRepresenter do
  let(:schema) { instance_double(API::V3::WorkPackages::Schema::WorkPackageSumsSchema, available_custom_fields: []) }
  let(:current_user) { build_stubbed(:user) }

  let(:representer) do
    described_class.create(schema, current_user:)
  end

  subject { representer.to_json }

  describe "overallCosts" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "overallCosts" }
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.overall_costs") }
      let(:required) { false }
      let(:writable) { false }
    end
  end

  describe "laborCosts" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "laborCosts" }
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.labor_costs") }
      let(:required) { false }
      let(:writable) { false }
    end
  end

  describe "materialCosts" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "materialCosts" }
      let(:type) { "String" }
      let(:name) { I18n.t("activerecord.attributes.work_package.material_costs") }
      let(:required) { false }
      let(:writable) { false }
    end
  end
end
