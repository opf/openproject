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
require_relative "../../../support/custom_field_filter"

RSpec.describe CostQuery::Filter::CustomFieldEntries, "with project-specific values" do
  include OpenProject::Reporting::SpecHelper::CustomFieldFilterHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:subproject) { create(:project, parent: project, types: [type]) }
  shared_let(:other_project) { create(:project, types: [type]) }
  shared_let(:invisible_project) { create(:project, types: [type]) }
  shared_let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist,
           types: [type], possible_values: %w[Alpha Beta Gamma Delta])
  end

  current_user do
    create(:user, member_with_permissions: { project => %i[view_work_packages],
                                             subproject => %i[view_work_packages],
                                             other_project => %i[view_work_packages] })
  end

  let(:engine_filter) { filter_class_name_string(custom_field).constantize }

  before do
    create(:project_specific_value_restriction, project:, custom_option: custom_field.custom_options.find_by!(value: "Alpha"))
    create(:project_specific_value_restriction, project: subproject,
                                                custom_option: custom_field.custom_options.find_by!(value: "Beta"))
    create(:project_specific_value_restriction, project: other_project,
                                                custom_option: custom_field.custom_options.find_by!(value: "Gamma"))
    create(:project_specific_value_restriction, project: invisible_project,
                                                custom_option: custom_field.custom_options.find_by!(value: "Delta"))

    CostQuery::Cache.reset!
    CostQuery::Filter.all
  end

  after do
    CostQuery::Cache.reset!
  end

  it "offers the values usable in the report's project and its subprojects" do
    expect(engine_filter.available_values(project:)).to eq([%w[Alpha Alpha], %w[Beta Beta]])
  end

  it "offers the values usable in any project the user sees work packages in without a project" do
    expect(engine_filter.available_values).to eq([%w[Alpha Alpha], %w[Beta Beta], %w[Gamma Gamma]])
  end

  describe Queries::CostReports::Filters::CustomFieldFilter do
    let(:query) { CostReportQuery.new(name: "probe", project:) }
    let(:filter) { described_class.create!(name: custom_field.column_name.to_sym, context: query) }

    it "allows the values usable in the report's project and its subprojects" do
      expect(filter.allowed_values).to eq([%w[Alpha Alpha], %w[Beta Beta]])
    end
  end
end
