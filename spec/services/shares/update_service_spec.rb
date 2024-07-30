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
require "services/base_services/behaves_like_update_service"

RSpec.describe Shares::UpdateService do
  let!(:groups_update_roles_service) do
    instance_double(Groups::UpdateRolesService).tap do |service_double|
      allow(Groups::UpdateRolesService)
        .to receive(:new)
              .and_return(service_double)

      allow(service_double)
        .to receive(:call)
    end
  end

  it_behaves_like "BaseServices update service" do
    let(:model_class) { Member }
    let!(:model_instance) { build_stubbed(:work_package_member, principal:) }
    let(:principal) { build_stubbed(:user) }
    let(:role) { build_stubbed(:view_work_package_role) }
    let(:call_attributes) { { roles: [role] } }

    context "when successful" do
      context "when the member being updates is a User" do
        it "doesn't attempt any group member post-processing" do
          instance_call

          expect(Groups::UpdateRolesService)
            .not_to have_received(:new)
        end
      end

      context "when the member being updated is a Group" do
        let(:principal) { build_stubbed(:group) }

        it "updates the group member's roles" do
          instance_call

          expect(Groups::UpdateRolesService)
            .to have_received(:new)
                  .with(principal,
                        current_user: user,
                        contract_class: EmptyContract)

          expect(groups_update_roles_service)
            .to have_received(:call)
        end
      end
    end
  end
end
