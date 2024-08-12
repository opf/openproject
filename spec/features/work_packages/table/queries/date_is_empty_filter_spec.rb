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

RSpec.describe 'Filter by date with "is empty"', :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  let(:member) do
    create(:member,
           user:,
           project:,
           roles: [create(:project_role)])
  end

  let(:work_package_with_start_date) do
    create(:work_package,
           project:,
           start_date: Time.zone.today)
  end

  let(:work_package_without_dates) do
    create(:work_package,
           project:)
  end

  let(:work_package_with_custom_date) do
    create(:work_package,
           project:)
  end

  let(:custom_field_date) do
    create(:date_wp_custom_field,
           name: "Date CF",
           is_filter: true,
           searchable: true) do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package_with_custom_date.type.custom_fields << custom_field

      create(:work_package_custom_value,
             custom_field:,
             customized: work_package_with_custom_date,
             value: Time.zone.today)
    end
  end

  def remove_default
    wp_table.expect_work_package_listed work_package_without_dates, work_package_with_start_date, work_package_with_custom_date

    filters.open
    filters.remove_filter("status")
  end

  before do
    login_as(user)
    member
    work_package_without_dates
    work_package_with_start_date
    work_package_with_custom_date
    custom_field_date

    wp_table.visit!
  end

  it "works as intended for regular fields" do
    remove_default

    filters.add_filter_by("Start date", "is empty", nil, "startDate")

    wp_table.expect_work_package_listed work_package_without_dates
    wp_table.ensure_work_package_not_listed! work_package_with_start_date
  end

  it "works as intended for custom fields" do
    remove_default

    filters.add_filter_by("Date CF", "is empty", nil, "customField#{custom_field_date.id}")

    wp_table.expect_work_package_listed work_package_without_dates
    wp_table.ensure_work_package_not_listed! work_package_with_custom_date
  end
end
