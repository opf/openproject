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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageCustomField do
  describe ".summable" do
    let!(:list_custom_field) do
      create(:list_wp_custom_field)
    end
    let!(:int_custom_field) do
      create(:integer_wp_custom_field)
    end
    let!(:float_custom_field) do
      create(:float_wp_custom_field)
    end

    context "with a summable field" do
      it "contains the custom_field" do
        expect(described_class.summable)
          .to contain_exactly(int_custom_field, float_custom_field)
      end
    end
  end

  describe "#type_ids_by_project_id" do
    let(:feature) { create(:type) }
    let(:epic) { create(:type) }
    let(:bug) { create(:type) }
    let(:custom_field) { create(:list_wp_custom_field, types: [feature, epic]) }

    let!(:project) { create(:project, types: [feature, epic, bug]) }
    let!(:other_project) { create(:project, types: [feature]) }

    before do
      create(:project, types: [bug])
      create(:project, active: false, types: [feature])
    end

    it "maps the active projects using the field to the types showing it there" do
      expect(custom_field.type_ids_by_project_id)
        .to match(project.id => contain_exactly(feature.id, epic.id), other_project.id => [feature.id])
    end
  end
end
