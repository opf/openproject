# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Alternative name autocompleting",
               :js,
               :with_cuprite do
  let!(:project)      { create(:project_with_types) }
  let!(:work_package) { create(:work_package, project:) }
  let!(:user)         { create(:admin) }

  let(:work_packages_page) { Pages::WorkPackagesTable.new(project) }
  let(:filters)            { Components::WorkPackages::Filters.new }
  let(:columns)            { Components::WorkPackages::Columns.new }

  before { login_as(user) }

  describe "Work package filter autocompleter" do
    it "allows discovering attributes by alternative names" do
      work_packages_page.visit!
      work_packages_page.expect_work_package_listed(work_package)

      filters.open!

      # Exact alternative match
      filters.expect_alternative_available_filter("Progress", "% Complete")
      # Partial alternative match
      filters.expect_alternative_available_filter("ime", "Work")
      # Exact "real" match
      filters.expect_alternative_available_filter("% Complete", "% Complete")
      # Partial "real" match
      filters.expect_alternative_available_filter("ork", "Work")
      # Indifferent to casing
      filters.expect_alternative_available_filter("% comp", "% Complete")
    end
  end

  describe "Work package view configuration form" do
    it "allows discovering attributes by alternative names" do
      work_packages_page.visit!
      work_packages_page.expect_work_package_listed(work_package)

      columns.open_modal
      # Exact alternative match
      columns.expect_alternative_available_column("Progress", "% Complete")
      # Partial alternative match
      columns.expect_alternative_available_column("ime", "Work")
      # Exact "real" match
      columns.expect_alternative_available_column("% Complete", "% Complete")
      # Partial "real" match
      columns.expect_alternative_available_column("hours", "Remaining work")
      # Indifferent to casing
      columns.expect_alternative_available_column("% comp", "% Complete")
    end
  end
end
