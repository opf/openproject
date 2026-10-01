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

RSpec.describe ProjectCustomFields::LoadService do
  let(:project) { create(:project) }
  let(:custom_field) { create(:list_project_custom_field, multi_value: true) }
  let(:project_custom_fields) { ProjectCustomField.where(id: project_custom_field_ids) }
  let(:project_custom_field_ids) { custom_field.id }

  subject(:service) { described_class.new(project:, project_custom_fields:) }

  describe "#get_eager_loaded_project_custom_field_values_for" do
    context "when the custom field has no values" do
      it "returns an empty array" do
        expect(service.get_eager_loaded_project_custom_field_values_for(custom_field.id)).to eq([])
      end
    end

    context "when the custom field has values" do
      # intentionally out of order
      let!(:cv2) { create(:custom_value, id: 1002, customized: project, custom_field:) }
      let!(:cv1) { create(:custom_value, id: 1001, customized: project, custom_field:) }
      let!(:cv3) { create(:custom_value, id: 1003, customized: project, custom_field:) }

      it "returns the values ordered by id" do
        expect(service.get_eager_loaded_project_custom_field_values_for(custom_field.id))
          .to eq([cv1, cv2, cv3])
      end

      it "returns empty array for other custom field" do
        expect(service.get_eager_loaded_project_custom_field_values_for(0))
          .to eq([])
      end

      context "when another custom field has values" do
        let(:other_custom_field) { create(:list_project_custom_field, multi_value: true) }
        let!(:other_cv) { create(:custom_value, customized: project, custom_field: other_custom_field) }
        let(:project_custom_field_ids) { [custom_field.id, other_custom_field.id] }

        it "returns values only for the requested custom field" do
          expect(service.get_eager_loaded_project_custom_field_values_for(custom_field.id))
            .to eq([cv1, cv2, cv3])
          expect(service.get_eager_loaded_project_custom_field_values_for(other_custom_field.id))
            .to eq([other_cv])
        end
      end

      context "when another project has values for the same custom field" do
        let!(:other_project_cv) { create(:custom_value, customized: create(:project), custom_field:) }

        it "returns only values for the given project" do
          expect(service.get_eager_loaded_project_custom_field_values_for(custom_field.id))
            .to eq([cv1, cv2, cv3])
        end
      end
    end
  end
end
