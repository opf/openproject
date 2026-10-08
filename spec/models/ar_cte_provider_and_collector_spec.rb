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

RSpec.describe "ActiveRecord CTE provider and collector" do # rubocop:disable RSpec/DescribeClass
  create_shared_association_defaults_for_work_package_factory

  shared_let(:work_package_in_cte) { create(:work_package) }
  shared_let(:work_package_not_in_cte) { create(:work_package) }

  before do
    # Register a SQL template whose per-query values arrive as `params` and are bound
    # via sanitize_sql_array.
    OpenProject::ActiveRecordExtensions::Cte::Aggregation.register :cte_aggregation_spec,
                                                                   ->(params) {
                                                                     ActiveRecord::Base.sanitize_sql_array(
                                                                       ["SELECT :id id", params]
                                                                     )
                                                                   }
  end

  after do
    OpenProject::ActiveRecordExtensions::Cte::Aggregation.deregister :cte_aggregation_spec
  end

  context "for subselects" do
    it "returns the value from the CTE" do
      # Desired SQL
      #
      # WITH cte_aggregation_spec AS (
      #   SELECT :id id
      # )
      #
      # SELECT *
      # FROM work_packages
      # WHERE work_packages.id IN (SELECT id FROM cte_aggregation_spec)

      provider = OpenProject::ActiveRecordExtensions::CteProvider.new(model: WorkPackage,
                                                                      params: { id: work_package_in_cte.id },
                                                                      with: "cte_aggregation_spec")
      scope = WorkPackage.where(id: provider)

      collected_scope = OpenProject::ActiveRecordExtensions::CteCollector.new(relation: scope)

      expect(collected_scope)
        .to contain_exactly(work_package_in_cte)
    end

    it "returns the value from the CTE even if deeply nested" do
      # Desired SQL
      #
      # WITH cte_aggregation_spec AS (
      #   SELECT :id id
      # )
      #
      # SELECT *
      # FROM work_packages
      # WHERE work_packages.id IN (
      #   SELECT id
      #   FROM work_packages
      #   WHERE work_packges.id IN (SELECT id FROM cte_aggregation_spec)
      # )

      provider = OpenProject::ActiveRecordExtensions::CteProvider.new(model: WorkPackage,
                                                                      params: { id: work_package_in_cte.id },
                                                                      with: "cte_aggregation_spec")
      scope = WorkPackage.where(id: WorkPackage.where(id: provider))

      collected_scope = OpenProject::ActiveRecordExtensions::CteCollector.new(relation: scope)

      expect(collected_scope)
        .to contain_exactly(work_package_in_cte)
    end

    it "works transparently without a collector" do
      # Desired SQL
      #
      # SELECT *
      # FROM work_packages
      # WHERE work_packages.id IN (
      #   SELECT id
      #   FROM work_packages
      #   WHERE work_packges.id IN (SELECT :id id)
      # )

      provider = OpenProject::ActiveRecordExtensions::CteProvider.new(model: WorkPackage,
                                                                      params: { id: work_package_in_cte.id },
                                                                      with: "cte_aggregation_spec")
      scope = WorkPackage.where(id: WorkPackage.where(id: provider))

      expect(scope)
        .to contain_exactly(work_package_in_cte)
    end
  end
end
