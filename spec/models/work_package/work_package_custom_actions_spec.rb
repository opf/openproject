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

RSpec.describe WorkPackage, "custom_actions" do
  let(:work_package) do
    build_stubbed(:work_package,
                  project:)
  end
  let(:project) { create(:project) }
  let(:status) { create(:status) }
  let(:other_status) { create(:status) }
  let(:user) do
    create(:user,
           member_with_roles: { work_package.project => role })
  end
  let(:role) do
    create(:project_role)
  end
  let(:conditions) do
    [CustomActions::Conditions::Status.new([status.id])]
  end

  let!(:custom_action) do
    action = build(:custom_action)
    action.conditions = conditions

    action.save!
    action
  end

  describe "#custom_actions" do
    context "with the custom action having no restriction" do
      let(:conditions) do
        []
      end

      before do
        work_package.status_id = status.id
      end

      it "returns the action" do
        expect(work_package.custom_actions(user))
          .to contain_exactly(custom_action)
      end
    end

    context "with a status restriction" do
      context "with the work package having the same status" do
        before do
          work_package.status_id = status.id
        end

        it "returns the action" do
          expect(work_package.custom_actions(user))
            .to contain_exactly(custom_action)
        end
      end

      context "with the work package having a different status" do
        before do
          work_package.status_id = other_status.id
        end

        it "does not return the action" do
          expect(work_package.custom_actions(user))
            .to be_empty
        end
      end
    end

    context "with a role restriction" do
      let(:conditions) do
        [CustomActions::Conditions::Role.new(role.id)]
      end

      context "with the user having the same role" do
        it "returns the action" do
          expect(work_package.custom_actions(user))
            .to contain_exactly(custom_action)
        end
      end

      context "with the condition requiring a different role" do
        let(:other_role) { create(:project_role) }

        let(:conditions) do
          [CustomActions::Conditions::Role.new(other_role.id)]
        end

        it "does not return the action" do
          expect(work_package.custom_actions(user))
            .to be_empty
        end
      end
    end
  end
end
