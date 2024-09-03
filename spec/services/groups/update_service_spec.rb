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
require "services/base_services/behaves_like_update_service"

RSpec.describe Groups::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:add_service_result) do
      ServiceResult.success
    end
    let!(:add_users_service) do
      add_service = instance_double(Groups::AddUsersService)

      allow(Groups::AddUsersService)
        .to receive(:new)
        .with(model_instance, current_user: user)
        .and_return(add_service)

      allow(add_service)
        .to receive(:call)
        .and_return(add_service_result)

      add_service
    end

    context "with newly created group_users" do
      let(:old_group_user) { build_stubbed(:group_user, user_id: 3) }
      let(:new_group_user) do
        build_stubbed(:group_user, user_id: 5).tap do |gu|
          allow(gu)
            .to receive(:saved_changes?)
            .and_return(true)
        end
      end
      let(:group_users) { [old_group_user, new_group_user] }

      before do
        allow(model_instance)
          .to receive(:group_users)
          .and_return(group_users)
      end

      context "with the AddUsersService being successful" do
        it "is successful" do
          expect(instance_call).to be_success
        end

        it "calls the AddUsersService" do
          instance_call

          expect(add_users_service)
            .to have_received(:call)
            .with(ids: [new_group_user.user_id])
        end
      end

      context "with the AddUsersService being unsuccessful" do
        let(:add_service_result) do
          ServiceResult.failure
        end

        it "is failure" do
          expect(instance_call).to be_failure
        end

        it "calls the AddUsersService" do
          instance_call

          expect(add_users_service)
            .to have_received(:call)
            .with(ids: [new_group_user.user_id])
        end
      end

      context "without any new group_users" do
        let(:group_users) { [old_group_user] }

        it "is successful" do
          expect(instance_call).to be_success
        end

        it "does not call the AddUsersService" do
          instance_call

          expect(add_users_service)
            .not_to have_received(:call)
        end
      end
    end
  end
end
