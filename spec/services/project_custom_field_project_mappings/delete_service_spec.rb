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
require "services/base_services/behaves_like_delete_service"

RSpec.describe ProjectCustomFieldProjectMappings::DeleteService do
  it_behaves_like "BaseServices delete service" do
    let(:factory) { :project_custom_field_project_mapping }
    let(:contract_class) do
      "#{namespace}::UpdateContract".constantize
    end
  end

  describe "calculated values", with_ee: %i[calculated_values] do
    using CustomFieldFormulaReferencing

    shared_let(:user) { create(:admin) }

    shared_let(:project) { create(:project) }
    shared_let(:project_custom_field_section) { create(:project_custom_field_section) }
    shared_let(:static) { create(:integer_project_custom_field, project_custom_field_section:) }
    shared_let(:calculated) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "#{static} * 7", project_custom_field_section:)
    end
    shared_let(:enabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "11", project_custom_field_section:)
    end
    shared_let(:disabled) do
      create(:calculated_value_project_custom_field, :skip_validations, formula: "13", project_custom_field_section:)
    end

    shared_let(:static_mapping) { create(:project_custom_field_project_mapping, project:, project_custom_field: static) }
    shared_let(:calculated_mapping) { create(:project_custom_field_project_mapping, project:, project_custom_field: calculated) }
    shared_let(:enabled_mapping) { create(:project_custom_field_project_mapping, project:, project_custom_field: enabled) }

    let(:instance) { described_class.new(user:, model:) }

    let(:without_calculated) { { static.id => "2", calculated.id => nil, enabled.id => "11", disabled.id => nil } }

    before do
      {
        static => 2,
        calculated => 14,
        enabled => 11
      }.each { |custom_field, value| create(:custom_value, custom_field:, value:, customized: project) }
    end

    context "when removing referenced static field" do
      let(:model) { static_mapping }

      it "recalculates the value" do
        expect(instance.call).to be_success

        project.reload
        expect(project.project_custom_fields).to contain_exactly(calculated, enabled)
        expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
      end
    end

    context "when removing calculated field" do
      let(:model) { calculated_mapping }

      it "recalculates the value" do
        expect(instance.call).to be_success

        project.reload
        expect(project.project_custom_fields).to contain_exactly(static, enabled)
        expect(project.custom_value_attributes(all: true)).to eq(without_calculated)
      end
    end
  end
end
