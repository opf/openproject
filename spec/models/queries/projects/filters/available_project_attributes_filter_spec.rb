#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Queries::Projects::Filters::AvailableProjectAttributesFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :available_project_attributes }
    let(:type) { :list_contains }
    let(:human_name) { "Available project attributes" }
  end

  it_behaves_like "list_contains query filter" do
    let(:project_custom_field_project_mapping1) { build_stubbed(:project_custom_field_project_mapping) }
    let(:project_custom_field_project_mapping2) { build_stubbed(:project_custom_field_project_mapping) }

    before do
      allow(ProjectCustomFieldProjectMapping)
        .to receive(:pluck)
        .with(:custom_field_id)
        .and_return([project_custom_field_project_mapping1.id,
                     project_custom_field_project_mapping2.id])
    end

    let(:name) { "Available project attributes" }
    let(:valid_values) { [project_custom_field_project_mapping1.id, project_custom_field_project_mapping2.id] }

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expected = [[project_custom_field_project_mapping1.id, project_custom_field_project_mapping1.id.to_s],
                    [project_custom_field_project_mapping2.id, project_custom_field_project_mapping2.id.to_s]]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end
end
