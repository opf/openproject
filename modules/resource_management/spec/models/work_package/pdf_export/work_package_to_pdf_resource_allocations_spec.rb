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

RSpec.describe WorkPackage::PDFExport::WorkPackageToPdf, "resource allocations",
               with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking resource_management]) }
  shared_let(:member) { create(:user, firstname: "Olga", lastname: "Ops", member_with_permissions: { project => [] }) }
  shared_let(:outsider) { create(:user, member_with_permissions: { create(:project) => [] }) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_resource_planners export_work_packages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  subject(:strings) do
    login_as(user)
    content = described_class.new(work_package, { footer_text: project.name }).export!.content
    PDF::Inspector::Text.analyze(content).strings
  end

  before do
    create(:resource_allocation, entity: work_package, principal: member, allocated_time: 8 * 60)
    create(:resource_allocation, entity: work_package, principal: outsider, allocated_time: 4 * 60)
  end

  it "lists the allocated time and the allocated resources" do
    expect(strings.each_cons(2).to_a).to include(
      [WorkPackage.human_attribute_name(:allocated_time), "12h"],
      [WorkPackage.human_attribute_name(:allocated_principals),
       "#{member.name}, #{I18n.t('resource_management.work_package_allocations_dialog.hidden_user')}"]
    )
    expect(strings.join(" ")).not_to include(outsider.name)
  end

  context "without the view_resource_planners permission" do
    let(:permissions) { %i[view_work_packages export_work_packages] }

    it "leaves out the allocation attributes" do
      expect(strings).not_to include(WorkPackage.human_attribute_name(:allocated_time),
                                     WorkPackage.human_attribute_name(:allocated_principals))
    end
  end

  context "without an enterprise token", with_ee: false do
    it "leaves out the allocation attributes" do
      expect(strings).not_to include(WorkPackage.human_attribute_name(:allocated_time),
                                     WorkPackage.human_attribute_name(:allocated_principals))
    end
  end
end
