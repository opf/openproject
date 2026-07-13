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

RSpec.describe WorkPackages::DeleteService, "integration", type: :model,
                                            with_settings: { cross_project_work_package_relations: true } do
  let(:project_a) { create(:project_with_types) }
  let(:project_b) { create(:project_with_types) }
  let(:role_a) { create(:project_role, permissions: %i[view_work_packages delete_work_packages]) }
  let(:role_b) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:user) do
    create(:user).tap do |u|
      create(:member, project: project_a, principal: u, roles: [role_a])
      create(:member, project: project_b, principal: u, roles: [role_b])
    end
  end

  let!(:parent) { create(:work_package, project: project_a, subject: "Parent") }
  let!(:child) { create(:work_package, project: project_b, parent:, subject: "Child") }

  subject(:call) { described_class.new(user:, model: parent).call }

  it "does not delete descendants in projects where the user lacks delete permission" do
    expect(call).to be_failure
    expect(WorkPackage.exists?(parent.id)).to be_truthy
    expect(WorkPackage.exists?(child.id)).to be_truthy
    expect(call.includes_error?(:base, :error_unauthorized)).to be(true)
  end
end
