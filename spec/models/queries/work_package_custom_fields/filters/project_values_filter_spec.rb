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

RSpec.describe Queries::WorkPackageCustomFields::Filters::ProjectValuesFilter,
               with_ee: %i[custom_field_hierarchies] do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_let(:plain) { create(:list_wp_custom_field, possible_values: %w[A]) }
  shared_let(:managed) do
    create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A], project_level_value_management: true)
  end
  shared_let(:extendable) do
    create(:list_wp_custom_field, possible_values: %w[A], allow_additional_project_values: true)
  end
  shared_let(:with_own_option) do
    create(:list_wp_custom_field, possible_values: %w[A]).tap do |field|
      field.custom_options.create!(value: "Own", project:)
    end
  end
  shared_let(:with_foreign_option) do
    create(:list_wp_custom_field, possible_values: %w[A]).tap do |field|
      field.custom_options.create!(value: "Foreign", project: other_project)
    end
  end
  shared_let(:with_restriction) do
    create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A]).tap do |field|
      create(:project_specific_value_restriction, project:, custom_option: field.custom_options.first)
    end
  end
  shared_let(:with_stale_restriction) do
    create(:list_wp_custom_field, :project_specific_blocklist, possible_values: %w[A]).tap do |field|
      create(:project_specific_value_restriction, project:, custom_option: field.custom_options.first, restriction: "allow")
    end
  end

  let!(:with_own_item) do
    create(:hierarchy_wp_custom_field).tap do |field|
      global_item = create(:hierarchy_item, parent: field.hierarchy_root)
      create(:hierarchy_item, parent: global_item, project:)
    end
  end

  subject(:result) do
    Queries::WorkPackageCustomFields::WorkPackageCustomFieldQuery.new
      .tap { |query| query.project = project }
      .where(:project_values, operator, [])
      .results
  end

  context "for all fields" do
    let(:operator) { "all" }

    it "returns every field" do
      expect(result).to contain_exactly(plain, managed, extendable, with_own_option, with_foreign_option,
                                        with_restriction, with_stale_restriction, with_own_item)
    end
  end

  context "for customizable fields" do
    let(:operator) { "customizable" }

    it "returns the fields project admins can manage or add values to" do
      expect(result).to contain_exactly(managed, extendable)
    end
  end

  context "for customized fields" do
    let(:operator) { "customized" }

    it "returns the fields with values or restrictions of the project" do
      expect(result).to contain_exactly(with_own_option, with_own_item, with_restriction)
    end
  end

  context "for fields with the same values in all projects" do
    let(:operator) { "uniform" }

    it "returns the fields without values or restrictions of the project" do
      expect(result).to contain_exactly(plain, managed, extendable, with_foreign_option, with_stale_restriction)
    end
  end
end
