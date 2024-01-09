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

require 'spec_helper'

RSpec.describe 'Estimated hours display' do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:hierarchy) { [] }

  let!(:work_packages) do
    build_work_package_hierarchy(
      hierarchy,
      :subject,
      :estimated_hours,
      shared_attributes: {
        project:
      }
    )
  end

  let(:parent) { work_packages.first }
  let(:child) { work_packages.last }

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w[id subject estimated_hours]

    query.save!
    query
  end

  let(:wp_table) { Pages::WorkPackagesTable.new project }

  before do
    WorkPackages::UpdateAncestorsService
      .new(user:, work_package: child)
      .call([:estimated_hours])

    login_as(user)
  end

  context "with both work and derived work" do
    let(:hierarchy) do
      [
        {
          ["Parent", 1] => [
            ["Child", 3]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, estimatedTime: "1 hΣ 3 h"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n1 hΣ 3 h")
    end
  end

  context "with just work" do
    let(:hierarchy) do
      [
        {
          ["Parent", 1] => [
            ["Child", 0]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, subject: parent.subject, estimatedTime: "1 h"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n1 h")
    end
  end

  context "with just derived work with (parent work 0 h)" do
    let(:hierarchy) do
      [
        {
          ["Parent", 0] => [
            ["Child", 3]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, subject: parent.subject, estimatedTime: "0 hΣ 3 h"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n0 hΣ 3 h")
    end
  end

  context "with just derived work (parent work unset)" do
    let(:hierarchy) do
      [
        {
          ["Parent", nil] => [
            ["Child", 3]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, subject: parent.subject, estimatedTime: "-Σ 3 h"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n-Σ 3 h")
    end
  end

  context "with neither work nor derived work (both 0 h)" do
    let(:hierarchy) do
      [
        {
          ["Parent", 0] => [
            ["Child", 0]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, subject: parent.subject, estimatedTime: "0 h"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n0 h")
    end
  end

  context "with neither work nor derived work (both unset)" do
    let(:hierarchy) do
      [
        {
          ["Parent", nil] => [
            ["Child", nil]
          ]
        }
      ]
    end

    it 'work package index', :js do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, subject: parent.subject, estimatedTime: "-"
      )
    end

    it 'work package details', :js do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n-")
    end
  end
end
