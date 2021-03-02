#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Work package filtering by bool custom field', js: true do
  let(:project) { FactoryBot.create :project }
  let(:type) { project.types.first }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let!(:bool_cf) do
    FactoryBot.create(:bool_wp_custom_field).tap do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages save_queries]) }
  let!(:work_package_true) do
    FactoryBot.create(:work_package,
                      type: type,
                      project: project).tap do |wp|
      wp.custom_field_values = { bool_cf.id => true }
      wp.save!
    end
  end
  let!(:work_package_false) do
    FactoryBot.create(:work_package,
                      type: type,
                      project: project).tap do |wp|
      wp.custom_field_values = { bool_cf.id => false }
      wp.save!
    end
  end
  let!(:work_package_without) do
    # Has no custom field value set
    FactoryBot.create(:work_package,
                      type: type,
                      project: project)
  end
  let!(:work_package_other_type) do
    # Does not have the custom field at all
    FactoryBot.create(:work_package,
                      type: project.types.last,
                      project: project)
  end

  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages save_queries]
  end

  it 'shows the work package matching the bool cf filter' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_true, work_package_false, work_package_without, work_package_other_type)

    filters.open

    # Add filtering by bool custom field which defaults to false
    filters.add_filter(bool_cf.name)

    # Turn the added filter to the "true" value.
    # Ideally this would be the default.
    page.find("#div-values-customField#{bool_cf.id} label").click

    wp_table.ensure_work_package_not_listed!(work_package_false, work_package_without, work_package_other_type)
    wp_table.expect_work_package_listed(work_package_true)

    wp_table.save_as('Saved query')

    wp_table.expect_and_dismiss_notification(message: 'Successful creation.')

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(work_package_false, work_package_without, work_package_other_type)
    wp_table.expect_work_package_listed(work_package_true)

    filters.open

    # Inverting the filter
    page.find("#div-values-customField#{bool_cf.id} label").click

    wp_table.ensure_work_package_not_listed!(work_package_true)
    wp_table.expect_work_package_listed(work_package_false, work_package_without, work_package_other_type)
  end
end
