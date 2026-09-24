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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter, with_ee: %i[resource_management] do
  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking resource_management]) }
  let(:permissions) { %i[view_work_packages view_resource_planners] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }
  let(:schema) { API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:) }

  subject(:generated) do
    described_class.create(schema, self_link: nil, current_user: user).to_json
  end

  before { login_as(user) }

  describe "allocatedTime" do
    it "is a read-only duration" do
      expect(generated).to be_json_eql("Duration".to_json).at_path("allocatedTime/type")
      expect(generated).to be_json_eql(false.to_json).at_path("allocatedTime/writable")
      expect(generated).to be_json_eql(false.to_json).at_path("allocatedTime/required")
      expect(generated)
        .to be_json_eql(I18n.t("activerecord.attributes.work_package.allocated_time").to_json)
        .at_path("allocatedTime/name")
    end

    context "without the view_resource_planners permission" do
      let(:permissions) { %i[view_work_packages] }

      it { is_expected.not_to have_json_path("allocatedTime") }
    end

    context "without an enterprise token", with_ee: false do
      it { is_expected.not_to have_json_path("allocatedTime") }
    end
  end
end
