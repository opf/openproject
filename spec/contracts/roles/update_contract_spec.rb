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
require_relative "shared_contract_examples"

RSpec.describe Roles::UpdateContract do
  it_behaves_like "roles contract" do
    let(:work_package_role) do
      build_stubbed(:work_package_role,
                    name: "Some name") do |r|
        r.name = role_name
        r.permissions = role_permissions
      end
    end

    let(:role) do
      build_stubbed(:project_role,
                    name: "Some name") do |r|
        r.name = role_name
        r.permissions = role_permissions
      end
    end

    let(:global_role) do
      build_stubbed(:global_role,
                    name: "Some name") do |r|
        r.name = role_name
        r.permissions = role_permissions
      end
    end

    subject(:contract) { described_class.new(role, current_user) }

    describe "validation" do
      context "with the type set manually" do
        before do
          role.type = "GlobalRole"
        end

        it "is invalid" do
          expect_valid(false, type: %i(error_readonly))
        end
      end
    end
  end
end
