# frozen_string_literal: true

#-- copyright
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
              project.types.each { it.custom_fields << cf }
              project.work_package_custom_fields << cf
            end
          end
        end
        shared_let(:multi_user_project) do
          create(:project, members: users[0..3].map { [it, role] }).tap do |project|
            [user_cf, multi_user_cf].each do |cf|
              project.work_package_custom_fields << cf
            end
          end
        end

        let(:user_cf_action) { Automations::Actions::CustomField.subclass_for(user_cf).new(custom_field_id: user_cf.id) }
        let(:multi_user_cf_action) { Automations::Actions::CustomField.subclass_for(multi_user_cf).new(custom_field_id: multi_user_cf.id) }
        let(:single_user_work_package) { create(:work_package, project: single_user_project) }
        let(:multi_user_work_package) { create(:work_package, project: multi_user_project) }

        let(:automation) do
          create(:automation,
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
