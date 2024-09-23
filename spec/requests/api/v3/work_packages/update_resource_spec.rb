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
require "rack/test"

RSpec.describe "API v3 Work package resource",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  create_shared_association_defaults_for_work_package_factory

  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:project) do
    create(:project, identifier: "test_project", public: false)
  end

  let(:work_package) do
    create(:work_package,
           project:,
           description: "lorem ipsum")
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions work_package_assigned] }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  describe "PATCH /api/v3/work_packages/:id" do
    let(:patch_path) { api_v3_paths.work_package work_package.id }
    let(:valid_params) do
      {
        _type: "WorkPackage",
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context "patch request" do
      before do
        patch patch_path, params.to_json
      end
    end

    shared_context "with application/hal+json content type" do
      before do
        header("Content-Type", "application/hal+json")
      end
    end

    context "user without needed permissions" do
      context "no permission to see the work package" do
        let(:work_package) { create(:work_package) }
        let(:current_user) { create(:user) }
        let(:params) { valid_params }

        include_context "patch request"

        it_behaves_like "not found",
                        I18n.t("api_v3.errors.not_found.work_package")
      end

      context "no permission to edit the work package" do
        let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_package_attachments]) }
        let(:current_user) do
          create(:user,
                 member_with_roles: { work_package.project => role })
        end
        let(:params) { valid_params }

        include_context "patch request"

        it_behaves_like "unauthorized access"
      end
    end

    context "user with needed permissions" do
      shared_examples_for "lock version updated" do
        it {
          expect(subject.body)
            .to be_json_eql(work_package.reload.lock_version)
                  .at_path("lockVersion")
        }
      end

      describe "notification" do
        let(:update_params) { valid_params.merge(subject: "Updated subject") }
        let(:other_user) do
          create(:user,
                 member_with_permissions: { work_package.project => %i(view_work_packages) },
                 notification_settings: [
                   build(:notification_setting,
                         work_package_created: true)
                 ])
        end

        before do
          other_user
          work_package

          perform_enqueued_jobs do
            patch patch_path, params.to_json
          end
        end

        context "without the parameter" do
          let(:params) { update_params }

          it "creates a notification" do
            expect(Notification.where(recipient: other_user, resource: work_package))
              .to exist
          end
        end

        context "with the parameter disabling notifications" do
          let(:patch_path) { "#{api_v3_paths.work_package work_package.id}?notify=false" }
          let(:params) { update_params }

          it "creates no notification" do
            expect(Notification)
              .not_to exist
          end
        end

        context "with the parameter enabling notifications" do
          let(:patch_path) { "#{api_v3_paths.work_package work_package.id}?notify=Something" }
          let(:params) { update_params }

          it "creates a notification" do
            expect(Notification.where(recipient: other_user, resource: work_package))
              .to exist
          end
        end
      end

      context "subject" do
        let(:params) { valid_params.merge(subject: "Updated subject") }

        include_context "with application/hal+json content type"
        include_context "patch request"

        it { expect(response).to have_http_status(:ok) }

        it "responds with updated work package subject" do
          expect(subject.body).to be_json_eql("Updated subject".to_json).at_path("subject")
        end

        it_behaves_like "lock version updated"

        context "for a user having assign_versions but lacking edit_work_packages permission" do
          let(:permissions) { %i[view_work_packages assign_versions] }

          include_context "patch request"

          it { expect(response).to have_http_status(:unprocessable_entity) }

          it "has a readonly error" do
            expect(response.body)
              .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyIsReadOnly".to_json)
                    .at_path("errorIdentifier")
          end
        end
      end

      context "description" do
        shared_examples_for "description updated" do
          it_behaves_like "API V3 formattable", "description" do
            let(:format) { "markdown" }

            subject { response.body }
          end

          it_behaves_like "lock version updated"
        end

        context "w/o value (empty)" do
          let(:raw) { nil }
          let(:html) { "" }
          let(:params) { valid_params.merge(description: { raw: nil }) }

          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it_behaves_like "description updated"
        end

        context "with value" do
          let(:raw) { "**Some text** *describing* **something**..." }
          let(:html) do
            '<p class="op-uc-p"><strong>Some text</strong> <em>describing</em> <strong>something</strong>...</p>'
          end
          let(:params) { valid_params.merge(description: { raw: }) }

          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it_behaves_like "description updated"
        end
      end

      context "schedule manually" do
        let(:schedule_manually) { true }
        let(:params) { valid_params.merge(scheduleManually: schedule_manually) }

        include_context "patch request"

        it { expect(response).to have_http_status(:ok) }

        it "updates the scheduling mode" do
          expect(subject.body).to be_json_eql(schedule_manually.to_json).at_path("scheduleManually")
        end
      end

      context "start date" do
        let(:date_string) { Date.current.iso8601 }
        let(:params) { valid_params.merge(startDate: date_string) }

        include_context "patch request"

        it { expect(response).to have_http_status(:ok) }

        it "responds with updated start date" do
          expect(subject.body).to be_json_eql(date_string.to_json).at_path("startDate")
        end

        it_behaves_like "lock version updated"
      end

      context "finish date" do
        let(:date_string) { Date.current.iso8601 }
        let(:params) { valid_params.merge(dueDate: date_string) }

        include_context "patch request"

        it { expect(response).to have_http_status(:ok) }

        it "responds with updated finish date" do
          expect(subject.body).to be_json_eql(date_string.to_json).at_path("dueDate")
        end

        it_behaves_like "lock version updated"
      end

      describe "remaining time" do
        let(:duration) { "PT12H30M" }
        let(:params) { valid_params.merge(remainingTime: duration) }

        include_context "patch request"

        it { expect(response).to have_http_status(:ok) }

        it "responds with updated finish date" do
          expect(subject.body).to be_json_eql(duration.to_json).at_path("remainingTime")
        end

        it_behaves_like "lock version updated"
      end

      context "status" do
        let(:target_status) { create(:status) }
        let(:status_link) { api_v3_paths.status target_status.id }
        let(:status_parameter) { { _links: { status: { href: status_link } } } }
        let(:params) { valid_params.merge(status_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context "valid status" do
          let!(:workflow) do
            create(:workflow,
                   type_id: work_package.type.id,
                   old_status: work_package.status,
                   new_status: target_status,
                   role: current_user.memberships[0].roles[0])
          end

          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with updated work package status" do
            expect(subject.body).to be_json_eql(target_status.name.to_json)
                                      .at_path("_embedded/status/name")
          end

          it_behaves_like "lock version updated"
        end

        context "invalid status" do
          include_context "patch request"

          it_behaves_like "constraint violation" do
            let(:message) do
              "Status " + I18n.t("activerecord.errors.models." \
                                 "work_package.attributes.status_id.status_transition_invalid")
            end
          end
        end

        context "wrong resource" do
          let(:status_link) { api_v3_paths.user current_user.id }

          include_context "patch request"

          it_behaves_like "invalid resource link" do
            let(:message) do
              I18n.t("api_v3.errors.invalid_resource",
                     property: "status",
                     expected: "/api/v3/statuses/:id",
                     actual: status_link)
            end
          end
        end
      end

      context "type" do
        let(:target_type) { create(:type) }
        let(:type_link) { api_v3_paths.type target_type.id }
        let(:type_parameter) { { _links: { type: { href: type_link } } } }
        let(:params) { valid_params.merge(type_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context "valid type" do
          before do
            project.types << target_type
          end

          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with updated work package type" do
            expect(subject.body).to be_json_eql(target_type.name.to_json)
                                      .at_path("_embedded/type/name")
          end

          it_behaves_like "lock version updated"
        end

        context "valid type changing custom fields" do
          let(:custom_field) { create(:work_package_custom_field) }
          let(:custom_field_parameter) { { custom_field.attribute_name(:camel_case) => true } }
          let(:params) { valid_params.merge(type_parameter).merge(custom_field_parameter) }

          before do
            project.types << target_type
            project.work_package_custom_fields << custom_field
            target_type.custom_fields << custom_field
          end

          include_context "patch request"

          it "responds with the new custom field having the desired value" do
            expect(subject.body)
              .to be_json_eql(true.to_json)
                    .at_path("customField#{custom_field.id}")
          end
        end

        context "invalid type" do
          include_context "patch request"

          it_behaves_like "constraint violation" do
            let(:message) { "Type #{I18n.t('activerecord.errors.messages.inclusion')}" }
          end
        end

        context "wrong resource" do
          let(:type_link) { api_v3_paths.user current_user.id }

          include_context "patch request"

          it_behaves_like "invalid resource link" do
            let(:message) do
              I18n.t("api_v3.errors.invalid_resource",
                     property: "type",
                     expected: "/api/v3/types/:id",
                     actual: type_link)
            end
          end
        end
      end

      context "project" do
        let(:target_project) do
          create(:project, public: false)
        end
        let(:project_link) { api_v3_paths.project target_project.id }
        let(:project_parameter) { { _links: { project: { href: project_link } } } }
        let(:params) { valid_params.merge(project_parameter) }
        let(:member_permissions) { [:move_work_packages] }

        before do
          create(:member,
                 user: current_user,
                 project: target_project,
                 roles: [create(:project_role, permissions: member_permissions)])

          allow(User).to receive(:current).and_return current_user
        end

        context "is changed" do
          include_context "patch request"

          it "is successful" do
            expect(response).to have_http_status(:ok)
          end

          it_behaves_like "lock version updated"

          it "responds with the project changed" do
            href = {
              href: project_link,
              title: target_project.name
            }
            expect(response.body).to be_json_eql(href.to_json).at_path("_links/project")
          end
        end

        context "with a custom field defined on the target project" do
          let(:member_permissions) { %i[move_work_packages edit_work_packages] }
          let(:custom_field) { create(:work_package_custom_field) }
          let(:custom_field_parameter) { { custom_field.attribute_name(:camel_case) => true } }
          let(:params) { valid_params.merge(project_parameter).merge(custom_field_parameter) }

          before do
            target_project.work_package_custom_fields << custom_field
            work_package.type.custom_fields << custom_field
          end

          include_context "patch request"

          it "responds with the new custom field having the desired value" do
            expect(subject.body)
              .to be_json_eql(true.to_json)
                    .at_path("customField#{custom_field.id}")
          end
        end
      end

      context "assignee and responsible" do
        let(:user) { create(:user, member_with_permissions: { project => %i[work_package_assigned] }) }
        let(:placeholder_user) do
          create(:placeholder_user,
                 member_with_roles: { project => role })
        end
        let(:params) { valid_params.merge(user_parameter) }
        let(:work_package) do
          create(:work_package,
                 project:,
                 assigned_to: current_user,
                 responsible: current_user)
        end

        before { login_as current_user }

        shared_context "setup group membership" do
          let(:group) { create(:group) }
          let(:group_role) { create(:project_role, permissions: %i[work_package_assigned]) }
          let!(:group_member) do
            create(:member,
                   principal: group,
                   project:,
                   roles: [group_role])
          end
        end

        shared_examples_for "handling people" do |property|
          let(:user_parameter) { { _links: { property => { href: user_href } } } }
          let(:href_path) { "_links/#{property}/href" }

          describe "nil" do
            let(:user_href) { nil }

            include_context "patch request"

            it { expect(response).to have_http_status(:ok) }

            it { expect(response.body).to be_json_eql(nil.to_json).at_path(href_path) }

            it_behaves_like "lock version updated"
          end

          describe "valid" do
            shared_examples_for "valid user assignment" do
              let(:title) { assigned_user.name.to_s.to_json }

              it { expect(response).to have_http_status(:ok) }

              it {
                expect(response.body)
                  .to be_json_eql(title)
                        .at_path("_links/#{property}/title")
              }

              it_behaves_like "lock version updated"
            end

            context "user" do
              let(:user_href) { api_v3_paths.user user.id }

              include_context "patch request"

              it_behaves_like "valid user assignment" do
                let(:assigned_user) { user }
              end
            end

            context "group" do
              let(:user_href) { api_v3_paths.user group.id }

              include_context "setup group membership", true
              include_context "patch request"

              it_behaves_like "valid user assignment" do
                let(:assigned_user) { group }
              end
            end

            context "placeholder user" do
              let(:user_href) { api_v3_paths.placeholder_user placeholder_user.id }

              include_context "patch request"

              it_behaves_like "valid user assignment" do
                let(:assigned_user) { placeholder_user }
              end
            end
          end

          describe "invalid" do
            include_context "patch request"

            context "user doesn't exist" do
              let(:user_href) { api_v3_paths.user 909090 }

              it_behaves_like "constraint violation" do
                let(:message) do
                  I18n.t("api_v3.errors.validation." \
                         "invalid_user_assigned_to_work_package",
                         property: WorkPackage.human_attribute_name(property))
                end
              end
            end

            context "user is not visible" do
              let(:invalid_user) { create(:user) }
              let(:user_href) { api_v3_paths.user invalid_user.id }

              it_behaves_like "constraint violation" do
                let(:message) do
                  I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                         property: WorkPackage.human_attribute_name(property))
                end
              end
            end

            context "wrong resource" do
              let(:user_href) { api_v3_paths.status work_package.status.id }

              include_context "patch request"

              it_behaves_like "invalid resource link" do
                let(:message) do
                  I18n.t("api_v3.errors.invalid_resource",
                         property:,
                         expected: "/api/v3/groups/:id' or '/api/v3/users/:id' or '/api/v3/placeholder_users/:id",
                         actual: user_href)
                end
              end
            end
          end
        end

        context "assingee" do
          it_behaves_like "handling people", "assignee"
        end

        context "responsible" do
          it_behaves_like "handling people", "responsible"
        end
      end

      context "version" do
        let(:target_version) { create(:version, project:) }
        let(:version_link) { api_v3_paths.version target_version.id }
        let(:version_parameter) { { _links: { version: { href: version_link } } } }
        let(:params) { valid_params.merge(version_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context "valid" do
          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with the work package assigned to the version" do
            expect(subject.body)
              .to be_json_eql(target_version.name.to_json)
                    .at_path("_embedded/version/name")
          end

          it_behaves_like "lock version updated"
        end

        context "for a user lacking the assign_versions permission" do
          let(:permissions) { %i[view_work_packages edit_work_packages] }

          include_context "patch request"

          it { expect(response).to have_http_status(:unprocessable_entity) }

          it "has a readonly error" do
            expect(response.body)
              .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyIsReadOnly".to_json)
                    .at_path("errorIdentifier")
          end
        end
      end

      context "category" do
        let(:target_category) { create(:category, project:) }
        let(:category_link) { api_v3_paths.category target_category.id }
        let(:category_parameter) { { _links: { category: { href: category_link } } } }
        let(:params) { valid_params.merge(category_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context "valid" do
          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with the work package assigned to the category" do
            expect(subject.body)
              .to be_json_eql(target_category.name.to_json)
                    .at_path("_embedded/category/name")
          end

          it_behaves_like "lock version updated"
        end
      end

      context "priority" do
        let(:target_priority) { create(:priority) }
        let(:priority_link) { api_v3_paths.priority target_priority.id }
        let(:priority_parameter) { { _links: { priority: { href: priority_link } } } }
        let(:params) { valid_params.merge(priority_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context "valid" do
          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with the work package assigned to the priority" do
            expect(subject.body)
              .to be_json_eql(target_priority.name.to_json)
                    .at_path("_embedded/priority/name")
          end

          it_behaves_like "lock version updated"
        end
      end

      context "budget" do
        let(:target_budget) { create(:budget, project:) }
        let(:budget_link) { api_v3_paths.budget target_budget.id }
        let(:budget_parameter) { { _links: { budget: { href: budget_link } } } }
        let(:params) { valid_params.merge(budget_parameter) }
        let(:permissions) { %i[view_work_packages edit_work_packages view_budgets] }

        before { login_as(current_user) }

        context "valid" do
          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with the work package and its new budget" do
            expect(subject.body).to be_json_eql(target_budget.subject.to_json)
                                      .at_path("_embedded/budget/subject")
          end
        end

        context "not valid" do
          let(:target_budget) { create(:budget) }

          include_context "patch request"

          it_behaves_like "constraint violation" do
            let(:message) { I18n.t("activerecord.errors.messages.inclusion") }
          end
        end
      end

      context "list custom field" do
        let(:custom_field) do
          create(:list_wp_custom_field)
        end

        let(:target_value) { custom_field.possible_values.last }

        let(:value_link) do
          api_v3_paths.custom_option target_value.id
        end

        let(:value_parameter) do
          { _links: { custom_field.attribute_name.camelize(:lower) => { href: value_link } } }
        end
        let(:params) { valid_params.merge(value_parameter) }

        before do
          allow(User).to receive(:current).and_return current_user
          work_package.project.work_package_custom_fields << custom_field
          work_package.type.custom_fields << custom_field
        end

        context "valid" do
          include_context "patch request"

          it { expect(response).to have_http_status(:ok) }

          it "responds with the work package assigned to the new value" do
            expect(subject.body)
              .to be_json_eql(value_link.to_json)
                    .at_path("_links/#{custom_field.attribute_name.camelize(:lower)}/href")
          end

          it_behaves_like "lock version updated"
        end
      end

      describe "update with read-only attributes" do
        describe "single read-only violation" do
          context "created and updated" do
            let(:tomorrow) { (DateTime.now + 1.day).utc.iso8601 }

            include_context "patch request"

            context "created_at" do
              let(:params) { valid_params.merge(createdAt: tomorrow) }

              it_behaves_like "read-only violation", "createdAt", WorkPackage, "Created on"
            end

            context "updated_at" do
              let(:params) { valid_params.merge(updatedAt: tomorrow) }

              it_behaves_like "read-only violation", "updatedAt", WorkPackage, "Updated on"
            end
          end
        end

        context "multiple read-only attributes" do
          let(:params) do
            valid_params.merge(createdAt: Date.today.iso8601, updatedAt: Date.today.iso8601)
          end

          include_context "patch request"

          it_behaves_like "multiple errors", 422

          it_behaves_like "multiple errors of the same type", 2, "PropertyIsReadOnly"

          it_behaves_like "multiple errors of the same type with details",
                          "attribute",
                          "attribute" => ["createdAt", "updatedAt"]
        end
      end

      context "invalid update" do
        context "single invalid attribute" do
          let(:params) { valid_params.tap { |h| h[:subject] = "" } }

          include_context "patch request"

          it_behaves_like "constraint violation" do
            let(:message) { "Subject can't be blank" }
          end
        end

        context "multiple invalid attributes" do
          let(:params) do
            valid_params
              .tap { |h| h[:subject] = "" }
              .merge(
                _links: {
                  parent: {
                    href: api_v3_paths.work_package("-123")
                  }
                }
              )
          end

          before do
            role.add_permission!(:manage_subtasks)
          end

          include_context "patch request"

          it_behaves_like "multiple errors", 422

          it_behaves_like "multiple errors of the same type", 3, "PropertyConstraintViolation"

          it_behaves_like "multiple errors of the same type with messages" do
            let(:message) { ["Subject can't be blank.", "Parent does not exist.", "Parent may not be accessed."] }
          end
        end

        context "missing lock version" do
          let(:params) { valid_params.except(:lockVersion) }

          include_context "patch request"

          it_behaves_like "update conflict"
        end

        context "stale object" do
          let(:params) { valid_params.merge(subject: "Updated subject") }

          before do
            params

            work_package.subject = "I am the first!"
            work_package.save!

            expect(valid_params[:lockVersion]).not_to eq(work_package.lock_version)
          end

          include_context "patch request"

          it_behaves_like "update conflict"
        end
      end

      context "claiming attachments" do
        let(:old_attachment) { create(:attachment, container: work_package) }
        let(:attachment) { create(:attachment, container: nil, author: current_user) }
        let(:params) do
          {
            lockVersion: work_package.lock_version,
            _links: {
              attachments: [
                href: api_v3_paths.attachment(attachment.id)
              ]
            }
          }
        end

        before do
          old_attachment
        end

        include_context "patch request"

        it "replaces the current with the provided attachments" do
          work_package.reload

          expect(work_package.attachments)
            .to match_array(attachment)
        end
      end
    end
  end
end
