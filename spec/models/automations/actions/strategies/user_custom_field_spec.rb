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

module Automations
  module Actions
    module Strategies
      RSpec.describe UserCustomField do
        shared_let(:role) do
          create(:project_role, permissions: %i[view_work_packages view_projects edit_work_packages])
        end
        shared_let(:user_cf) { create(:user_wp_custom_field) }
        shared_let(:multi_user_cf) { create(:multi_user_wp_custom_field) }
        shared_let(:users) { create_list(:user, 5) }
        shared_let(:single_user_project) do
          create(:project, members: [[users[0], role]]).tap do |project|
            [user_cf, multi_user_cf].each do |cf|
              project.enabled_variants.each { it.custom_field_ids |= [cf.id] }
            end
          end
        end
        shared_let(:multi_user_project) do
          create(:project, members: users[0..3].map { [it, role] }).tap do |project|
            [user_cf, multi_user_cf].each do |cf|
            end
          end
        end

        let(:user_cf_action) { Automations::Actions::CustomField.for("custom_field_#{user_cf.id}").new }
        let(:multi_user_cf_action) { Automations::Actions::CustomField.for("custom_field_#{multi_user_cf.id}").new }
        let(:single_user_work_package) { create(:work_package, project: single_user_project) }
        let(:multi_user_work_package) { create(:work_package, project: multi_user_project) }

        let(:automation) do
          create(:automation, :with_button_trigger,
                 type_conditions: [single_user_work_package.type],
                 project_conditions: [single_user_project],
                 actions: [user_cf_action, multi_user_cf_action])
        end

        let(:user) { users[0] }

        context "when no users can be assigned to the single value custom field" do
          before do
            user_cf_action.values = users[4].id
            multi_user_cf_action.values = users[1..3].map(&:id)
            automation.save
          end

          it "fails with an error" do
            login_as user
            result = UpdateWorkPackageService.new(user:, action: automation)
                                             .call(work_package: single_user_work_package)

            expect(result).to be_failure
            expect(result.errors.size).to eq(1)

            updated = result.result.reload
            expect(updated.send("custom_field_#{multi_user_cf.id}")).to eq([nil])
            expect(updated.send("custom_field_#{user_cf.id}")).to be_nil
          end
        end

        context "when at least one user can be assigned to custom field" do
          before do
            user_cf_action.values = user.id
            multi_user_cf_action.values = users[0..3].map(&:id)
            automation.save
            login_as user
          end

          it "succeeds" do
            result = UpdateWorkPackageService.new(user:, action: automation).call(work_package: single_user_work_package)
            expect(result).to be_success

            multi_user_result = UpdateWorkPackageService.new(user:, action: automation)
                                                        .call(work_package: multi_user_work_package)

            expect(multi_user_result).to be_success
          end

          it "saves the custom field values on the work package" do
            result = UpdateWorkPackageService.new(user:, action: automation)
                                             .call(work_package: single_user_work_package)

            updated = result.result.reload
            expect(updated.send("custom_field_#{user_cf.id}")).to eq(user)
            expect(updated.send("custom_field_#{multi_user_cf.id}")).to eq([user])

            muti_user_result = UpdateWorkPackageService.new(user:, action: automation)
                                             .call(work_package: multi_user_work_package)

            updated = muti_user_result.result.reload
            expect(updated.send("custom_field_#{user_cf.id}")).to eq(user)
            expect(updated.send("custom_field_#{multi_user_cf.id}")).to eq(users[0..3])
          end
        end

        describe "handling of the 'me' values" do
          before do
            user_cf_action.values = "current_user"
            multi_user_cf_action.values = ["current_user"] + users[1..3].map(&:id)
            automation.save
            login_as user
          end

          it "assigns the current user to the custom field" do
            result = UpdateWorkPackageService.new(user:, action: automation)
                                             .call(work_package: single_user_work_package)

            updated = result.result.reload
            expect(updated.send("custom_field_#{user_cf.id}")).to eq(user)
            expect(updated.send("custom_field_#{multi_user_cf.id}")).to eq([user])
          end
        end
      end
    end
  end
end
