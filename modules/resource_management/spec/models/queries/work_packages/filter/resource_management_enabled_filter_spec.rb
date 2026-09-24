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

RSpec.describe Queries::WorkPackages::Filter::ResourceManagementEnabledFilter do
  shared_let(:managed_project) do
    create(:project, enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:plain_project) { create(:project, enabled_module_names: %w[work_package_tracking]) }

  shared_let(:managed_work_package) { create(:work_package, project: managed_project) }
  shared_let(:plain_work_package) { create(:work_package, project: plain_project) }

  shared_let(:user) { create(:admin) }

  before { login_as(user) }

  def results_for(operator, values)
    query = Query.new_default(project: nil, user:)
    query.add_filter("resource_management_enabled", operator, values)

    query.results.work_packages
  end

  it "is registered on the work package query but withheld from the filter picker" do
    expect(Queries::Register.filters[Query]).to include(described_class)
    expect(Queries::Register.excluded_filters).to include(described_class)
  end

  describe "filtering for true" do
    it "keeps only work packages whose project enables the module" do
      expect(results_for("=", ["t"]))
        .to contain_exactly(managed_work_package)
    end
  end

  describe "filtering for false" do
    it "keeps only work packages whose project does not enable the module" do
      expect(results_for("=", ["f"]))
        .to contain_exactly(plain_work_package)
    end
  end

  it "does not additionally require resource management permissions" do
    member = create(:user,
                    member_with_permissions: { managed_project => %i[view_work_packages] })
    login_as(member)

    query = Query.new_default(project: nil, user: member)
    query.add_filter("resource_management_enabled", "=", ["t"])

    expect(query.results.work_packages).to contain_exactly(managed_work_package)
  end
end
