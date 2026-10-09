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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "services/base_services/behaves_like_update_service"

RSpec.describe CustomFields::LinkWithRoleService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:model_instance) { build_stubbed(:project_custom_field, :user) }
  end

  describe "#modify_exiting_memberships" do
    shared_let(:user) { create(:admin) }

    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    let(:old_role) { create(:project_role) }
    let(:project_role1) { create(:project_role) }
    let(:project_role2) { create(:project_role) }

    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    let(:custom_field) { create(:user_project_custom_field, multi_value: true, projects: [project1, project2]) }
    let(:contract_class) { CustomFields::UpdateContract }
    let(:contract_instance) { instance_double(contract_class, validate: true) }

    let(:instance) { described_class.new(user:, model: custom_field, contract_class:) }

    subject { instance.call(attributes) }

    before do
      User.current = user
      allow(contract_class).to receive(:new).with(custom_field, user, options: {}).and_return(contract_instance)
    end

    context "when the field was not associated with a role before" do
      context "when assigning a role" do
        let(:attributes) { { role_id: project_role2.id } }

        context "and there are custom values for the field" do
          before do
            build(:custom_value, custom_field:, value: user1.id, customized: project1).tap { it.save(validate: false) }
            build(:custom_value, custom_field:, value: user2.id, customized: project1).tap { it.save(validate: false) }
            build(:custom_value, custom_field:, value: user3.id, customized: project2).tap { it.save(validate: false) }
          end

          context "and the users do not have memberships in the projects yet" do
            it "adds memberships for the users with the new role" do
              expect { subject }
                .to change { project1.memberships.count }.by(2)
                .and change { project2.memberships.count }.by(1)

              expect(project1.memberships.find_by(principal: user1).roles).to contain_exactly(project_role2)
              expect(project1.memberships.find_by(principal: user2).roles).to contain_exactly(project_role2)
              expect(project2.memberships.find_by(principal: user3).roles).to contain_exactly(project_role2)
            end
          end

          context "and some users already have memberships in the projects" do
            before do
              create(:member, user: user2, project: project1, roles: [old_role])
            end

            it "adds memberships for the users with the new role" do
              expect { subject }
                .to change { project1.memberships.count }.by(1)
                .and change { project2.memberships.count }.by(1)

              expect(project1.memberships.find_by(principal: user1).roles).to contain_exactly(project_role2)
              expect(project1.memberships.find_by(principal: user2).roles).to contain_exactly(old_role, project_role2)
              expect(project2.memberships.find_by(principal: user3).roles).to contain_exactly(project_role2)
            end
          end
        end

        context "and there are no custom values for the field" do
          it "does not change memberships" do
            expect { subject }.not_to change(Member, :count)
          end
        end
      end
    end

    context "when the field was associated with a role before" do
      let(:custom_field) do
        create(:user_project_custom_field, multi_value: true, projects: [project1, project2], role: project_role1)
      end

      context "when changing the role" do
        let(:attributes) { { role_id: project_role2.id } }

        context "and there are custom values for the field" do
          before do
            create(:member, user: user1, project: project1, roles: [project_role1])
            create(:custom_value, custom_field:, value: user1.id, customized: project1)

            create(:member, user: user2, project: project1, roles: [project_role1, old_role])
            create(:custom_value, custom_field:, value: user2.id, customized: project1)

            create(:member, user: user3, project: project2, roles: [project_role1])
            create(:custom_value, custom_field:, value: user3.id, customized: project2)
          end

          it "updates memberships for the users with the new role" do
            # no new memberships should be created
            expect { subject }.not_to change(Member, :count)

            expect(project1.memberships.find_by(principal: user1).roles).to contain_exactly(project_role2)
            expect(project1.memberships.find_by(principal: user2).roles).to contain_exactly(project_role2, old_role)
            expect(project2.memberships.find_by(principal: user3).roles).to contain_exactly(project_role2)
          end
        end

        context "and there are no custom values for the field" do
          it "does not change memberships" do
            expect { subject }.not_to change(Member, :count)
          end
        end
      end

      context "when removing the role" do
        let(:attributes) { { role_id: nil } }

        context "and there are no custom values for the field" do
          it "does not change memberships" do
            expect { subject }.not_to change(Member, :count)
          end
        end

        context "and there are custom values for the field" do
          before do
            create(:member, user: user1, project: project1, roles: [project_role1])
            create(:custom_value, custom_field:, value: user1.id, customized: project1)

            create(:member, user: user2, project: project1, roles: [project_role1, old_role])
            create(:custom_value, custom_field:, value: user2.id, customized: project1)

            create(:member, user: user3, project: project2, roles: [project_role1])
            create(:custom_value, custom_field:, value: user3.id, customized: project2)
          end

          it "updates and deletes memberships" do
            # membership for user2 stays in tact due to other role
            expect { subject }.to change(Member, :count).by(-2)

            expect(project1.memberships.find_by(principal: user1)).to be_nil
            expect(project1.memberships.find_by(principal: user2).roles).to contain_exactly(old_role)
            expect(project2.memberships.find_by(principal: user3)).to be_nil
          end
        end
      end
    end
  end
end
