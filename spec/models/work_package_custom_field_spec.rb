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

  describe ".form_counts" do
    let(:feature) { create(:type) }
    let(:epic) { create(:type) }

    it "returns an empty hash when no field is contained in a form" do
      create(:list_wp_custom_field)

      expect(described_class.form_counts).to eq({})
    end

    it "counts the forms each field is contained in and keys them independently by field id" do
      in_two_forms = create(:list_wp_custom_field, types: [feature, epic])
      in_one_form = create(:list_wp_custom_field, types: [feature])
      orphan_field = create(:list_wp_custom_field)

      counts = described_class.form_counts

      expect(counts).to eq(in_two_forms.id => 2, in_one_form.id => 1)
      expect(counts).not_to have_key(orphan_field.id)
    end

    it "ignores built-in attributes rather than bucketing them under a nil key" do
      create(:list_wp_custom_field, types: [feature])

      expect(described_class.form_counts.keys).not_to include(nil)
    end

    it "does not count a form where the field sits in an inactive, ungrouped membership" do
      field = create(:list_wp_custom_field, types: [feature])
      create(:form_configuration_attribute, custom_field: field, form_configuration: create(:form_configuration))

      expect(described_class.form_counts).to eq(field.id => 1)
    end
  end
end
