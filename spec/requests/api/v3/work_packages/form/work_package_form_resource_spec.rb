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

RSpec.describe "API v3 Work package form resource" do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  shared_let(:all_allowed_permissions) { %i[view_work_packages edit_work_packages assign_versions view_budgets] }
  shared_let(:assign_permissions) { %i[view_work_packages assign_versions] }
  shared_let(:cf_all) { create(:work_package_custom_field, is_for_all: true, field_format: "text") }
  shared_let(:type) { create(:type_bug, custom_fields: [cf_all]) }
  shared_let(:project) { create(:project, public: false, types: [type]) }
  shared_let(:authorized_user) do
    create(:user, member_with_permissions: { project => all_allowed_permissions })
  end
  shared_let(:work_package) do
    # Prevent executing as potentially unsaved AnyonymousUser which would
    # lead to the creation failing as the journal cannot be written with user_id = nil.
    User.execute_as authorized_user do
      create(:work_package, project:)
    end
  end
  shared_let(:authorized_assign_user) do
    create(:user, member_with_permissions: { project => assign_permissions })
  end
  shared_let(:unauthorized_user) { create(:user) }

  describe "#post" do
    let(:post_path) { api_v3_paths.work_package_form work_package.id }
    let(:valid_params) do
      {
        _type: "WorkPackage",
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context "with post request" do
      before do
        login_as(current_user)
        post post_path, (params ? params.to_json : nil), "CONTENT_TYPE" => "application/json"
      end
    end

    context "for a user without needed permissions" do
      let(:params) { {} }

      include_context "with post request" do
        let(:current_user) { unauthorized_user }
      end

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end

    context "for a user with all edit permissions" do
      let(:params) { nil }
      let(:current_user) { authorized_user }

      context "with non-existing work package" do
        let(:post_path) { api_v3_paths.work_package_form "eeek" }

        include_context "with post request"

        it_behaves_like "param validation error" do
          let(:id) { "eeek" }
          let(:type) { "WorkPackage" }
        end
      end

      context "with existing work package" do
        shared_examples_for "valid payload" do
          subject { last_response.body }

          it { expect(last_response).to have_http_status(:ok) }

          it { is_expected.to have_json_path("_embedded/payload") }

          it { is_expected.to have_json_path("_embedded/payload/lockVersion") }

          it { is_expected.to have_json_path("_embedded/payload/subject") }

          it_behaves_like "API V3 formattable", "_embedded/payload/description" do
            let(:format) { "markdown" }
            let(:raw) { defined?(raw_value) ? raw_value : work_package.description.to_s }
            let(:html) do
              defined?(html_value) ? html_value : "<p class=\"op-uc-p\">#{work_package.description}</p>"
            end
          end

          it "denotes subject to be writable" do
            expect(subject)
              .to be_json_eql(true)
              .at_path("_embedded/schema/subject/writable")
          end

          it "denotes version to be writable" do
            expect(subject)
              .to be_json_eql(true)
              .at_path("_embedded/schema/version/writable")
          end

          it "denotes string custom_field to be writable" do
            expect(subject)
              .to be_json_eql(true)
              .at_path("_embedded/schema/#{cf_all.attribute_name.camelcase(:lower)}/writable")
          end
        end

        shared_examples_for "valid payload with initial values" do
          it {
            expect(subject.body).to be_json_eql(work_package.lock_version.to_json)
              .at_path("_embedded/payload/lockVersion")
          }

          it {
            expect(subject.body).to be_json_eql(work_package.subject.to_json)
              .at_path("_embedded/payload/subject")
          }
        end

        shared_examples_for "having no errors" do
          it {
            expect(subject.body).to be_json_eql({}.to_json)
              .at_path("_embedded/validationErrors")
          }
        end

        shared_examples_for "having an error" do |property|
          it { expect(subject.body).to have_json_path("_embedded/validationErrors/#{property}") }

          describe "error body" do
            let(:error_id) { "urn:openproject-org:api:v3:errors:PropertyConstraintViolation" }

            let(:error_body) { parse_json(subject.body)["_embedded"]["validationErrors"][property] }

            it { expect(error_body["errorIdentifier"]).to eq(error_id) }
          end
        end

        describe "body" do
          context "as empty" do
            include_context "with post request"

            it_behaves_like "valid payload"

            it_behaves_like "valid payload with initial values"

            it_behaves_like "having no errors"
          end

          context "for filled" do
            let(:valid_params) do
              {
                _type: "WorkPackage",
                lockVersion: work_package.lock_version
              }
            end

            describe "no change" do
              let(:params) { valid_params }

              include_context "with post request"

              it_behaves_like "valid payload"

              it_behaves_like "valid payload with initial values"

              it_behaves_like "having no errors"
            end

            context "for invalid content" do
              before do
                allow(User).to receive(:current).and_return current_user
                post post_path, "{ ,", "CONTENT_TYPE" => "application/json; charset=utf-8"
              end

              it_behaves_like "parse error",
                              "unexpected comma (after ) at line 1, column 3"
            end

            describe "lock version" do
              context "with missing lock version" do
                let(:params) { valid_params.except(:lockVersion) }

                include_context "with post request"

                it_behaves_like "update conflict"
              end

              context "with stale object" do
                let(:params) { valid_params.merge(subject: "Updated subject") }

                before do
                  params

                  work_package.subject = "I am the first!"
                  work_package.save!
                end

                it { expect(valid_params[:lockVersion]).not_to eq(work_package.lock_version) }

                include_context "with post request"

                it { expect(last_response).to have_http_status(:conflict) }

                it_behaves_like "update conflict"
              end
            end

            describe "subject" do
              include_context "with post request"

              context "for valid subject" do
                let(:params) { valid_params.merge(subject: "Updated subject") }

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package subject" do
                  expect(subject.body).to be_json_eql("Updated subject".to_json)
                    .at_path("_embedded/payload/subject")
                end
              end

              context "for invalid subject" do
                let(:params) { valid_params.merge(subject: nil) }

                it_behaves_like "valid payload"

                it_behaves_like "having an error", "subject"

                it "responds with updated work package subject" do
                  expect(subject.body).to be_json_eql(nil.to_json)
                    .at_path("_embedded/payload/subject")
                end
              end
            end

            describe "description" do
              let(:path) { "_embedded/payload/description/raw" }
              let(:description) { "**Some text** *describing* **something**..." }
              let(:params) { valid_params.merge(description: { raw: description }) }

              include_context "with post request"

              it_behaves_like "valid payload" do
                let(:raw_value) { description }
                let(:html_value) do
                  '<p class="op-uc-p"><strong>Some text</strong> <em>describing</em> ' \
                    "<strong>something</strong>...</p>"
                end
              end

              it_behaves_like "having no errors"
            end

            describe "start date" do
              include_context "with post request"

              context "for valid date" do
                let(:params) { valid_params.merge(startDate: "2015-01-31") }

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package" do
                  expect(subject.body).to be_json_eql("2015-01-31".to_json)
                    .at_path("_embedded/payload/startDate")
                end
              end

              context "for invalid date" do
                let(:params) { valid_params.merge(startDate: "not a date") }

                it_behaves_like "format error",
                                I18n.t("api_v3.errors.invalid_format",
                                       property: "startDate",
                                       expected_format: I18n.t("api_v3.errors.expected.date"),
                                       actual: "not a date")
              end
            end

            describe "finish date" do
              include_context "with post request"

              context "for valid date" do
                let(:params) { valid_params.merge(dueDate: "2015-01-31") }

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package" do
                  expect(subject.body).to be_json_eql("2015-01-31".to_json)
                    .at_path("_embedded/payload/dueDate")
                end
              end

              context "for invalid date" do
                let(:params) { valid_params.merge(dueDate: "not a date") }

                it_behaves_like "format error",
                                I18n.t("api_v3.errors.invalid_format",
                                       property: "dueDate",
                                       expected_format: I18n.t("api_v3.errors.expected.date"),
                                       actual: "not a date")
              end
            end

            describe "remaining work" do
              include_context "with post request"

              context "for valid duration" do
                let(:params) { valid_params.merge(remainingTime: "PT12H45M") }

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package" do
                  expect(subject.body).to be_json_eql("PT12H45M".to_json)
                    .at_path("_embedded/payload/remainingTime")
                end
              end

              context "for invalid duration" do
                let(:params) { valid_params.merge(remainingTime: "not a duration") }

                it_behaves_like "format error",
                                I18n.t("api_v3.errors.invalid_format",
                                       property: "remainingTime",
                                       expected_format: I18n.t("api_v3.errors.expected.duration"),
                                       actual: "not a duration")
              end
            end

            describe "status" do
              let(:path) { "_embedded/payload/_links/status/href" }
              let(:target_status) { create(:status) }
              let(:status_link) { api_v3_paths.status target_status.id }
              let(:status_parameter) { { _links: { status: { href: status_link } } } }
              let(:params) { valid_params.merge(status_parameter) }

              context "for valid status" do
                let!(:workflow) do
                  create(:workflow,
                         type_id: work_package.type.id,
                         old_status: work_package.status,
                         new_status: target_status,
                         role: current_user.memberships[0].roles[0])
                end

                include_context "with post request"

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package status" do
                  expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                end

                it "stills show the original allowed statuses" do
                  expect(subject.body).to be_json_eql(status_link.to_json)
                    .at_path("_embedded/schema/status/_links/allowedValues/1/href")
                end
              end

              context "for invalid status" do
                context "when no transition" do
                  include_context "with post request"

                  it_behaves_like "valid payload"

                  it_behaves_like "having an error", "status"

                  it "responds with updated work package status" do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context "when status does not exist" do
                  let(:error_id) do
                    "urn:openproject-org:api:v3:errors:MultipleErrors".to_json
                  end
                  let(:status_link) { api_v3_paths.status -1 }

                  include_context "with post request"

                  it_behaves_like "valid payload"

                  it_behaves_like "having an error", "status"

                  it "responds with updated work package status" do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context "for wrong resource" do
                  let(:status_link) { api_v3_paths.user authorized_user.id }

                  include_context "with post request"

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
            end

            describe "assignee and responsible" do
              shared_examples_for "handling people" do |property|
                let(:path) { "_embedded/payload/_links/#{property}/href" }
                let(:visible_user) do
                  create(:user,
                         member_with_permissions: { project => [:work_package_assigned] })
                end
                let(:user_parameter) { { _links: { property => { href: user_link } } } }
                let(:params) { valid_params.merge(user_parameter) }

                shared_examples_for "having updated work package principal" do
                  it "responds with updated work package #{property}" do
                    expect(subject.body).to be_json_eql(user_link.to_json).at_path(path)
                  end
                end

                context "valid #{property}" do
                  shared_examples_for "valid user assignment" do
                    include_context "with post request"

                    it_behaves_like "valid payload"

                    it_behaves_like "having no errors"

                    it_behaves_like "having updated work package principal"
                  end

                  context "for empty user" do
                    let(:user_link) { nil }

                    it_behaves_like "valid user assignment"
                  end

                  context "for existing user" do
                    let(:user_link) { api_v3_paths.user visible_user.id }

                    it_behaves_like "valid user assignment"
                  end

                  context "for existing group" do
                    let(:user_link) { api_v3_paths.group group.id }
                    let(:group) { create(:group) }
                    let(:role) { create(:project_role, permissions: %i[work_package_assigned]) }
                    let(:group_member) do
                      create(:member,
                             principal: group,
                             project:,
                             roles: [role])
                    end

                    before do
                      group_member.save!
                    end

                    it_behaves_like "valid user assignment"
                  end

                  context "for existing placeholder_user" do
                    let(:user_link) { api_v3_paths.placeholder_user placeholder_user.id }
                    let(:placeholder_user) do
                      create(:placeholder_user,
                             member_with_permissions: { project => %i[work_package_assigned] })
                    end

                    it_behaves_like "valid user assignment"
                  end
                end

                context "invalid #{property}" do
                  context "for non-existing user" do
                    let(:user_link) { api_v3_paths.user 4200 }

                    include_context "with post request"

                    it_behaves_like "valid payload"

                    it_behaves_like "having an error", property

                    it_behaves_like "having updated work package principal"
                  end

                  context "for wrong resource" do
                    let(:user_link) { api_v3_paths.status work_package.status.id }

                    include_context "with post request"

                    it_behaves_like "invalid resource link" do
                      let(:message) do
                        I18n.t("api_v3.errors.invalid_resource",
                               property:,
                               expected: "/api/v3/groups/:id' or '/api/v3/users/:id' or '/api/v3/placeholder_users/:id",
                               actual: user_link)
                      end
                    end
                  end
                end
              end

              it_behaves_like "handling people", "assignee"

              it_behaves_like "handling people", "responsible"
            end

            describe "version" do
              let(:path) { "_embedded/payload/_links/version/href" }
              let(:target_version) { create(:version, project:, start_date: Time.zone.today - 2.days) }
              let(:other_version) { create(:version, project:, start_date: Time.zone.today - 1.day) }
              let(:version_link) { api_v3_paths.version target_version.id }
              let(:version_parameter) { { _links: { version: { href: version_link } } } }
              let(:params) { valid_params.merge(version_parameter) }

              describe "allowed values" do
                before do
                  other_version
                end

                include_context "with post request"

                it "lists all versions available for the project" do
                  [target_version, other_version].sort.each_with_index do |v, i|
                    expect(subject.body).to be_json_eql(api_v3_paths.version(v.id).to_json)
                      .at_path("_embedded/schema/version/_links/allowedValues/#{i}/href")
                  end
                end
              end

              context "for valid version" do
                include_context "with post request"

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package version" do
                  expect(subject.body).to be_json_eql(version_link.to_json).at_path(path)
                end
              end
            end

            describe "category" do
              let(:path) { "_embedded/payload/_links/category/href" }
              let(:links_path) { "_embedded/schema/category/_links" }
              let(:target_category) { create(:category, project:) }
              let(:other_category) { create(:category, project:) }
              let(:category_link) { api_v3_paths.category target_category.id }
              let(:category_parameter) { { _links: { category: { href: category_link } } } }
              let(:params) { valid_params.merge(category_parameter) }

              describe "allowed values" do
                before do
                  other_category
                end

                include_context "with post request"

                it "lists the categories" do
                  [target_category, other_category].sort.each_with_index do |c, i|
                    expect(subject.body).to be_json_eql(api_v3_paths.category(c.id).to_json)
                      .at_path("#{links_path}/allowedValues/#{i}/href")
                  end
                end
              end

              context "for valid category" do
                include_context "with post request"

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package category" do
                  expect(subject.body).to be_json_eql(category_link.to_json).at_path(path)
                end
              end
            end

            describe "priority" do
              let(:path) { "_embedded/payload/_links/priority/href" }
              let(:links_path) { "_embedded/schema/priority/_links" }
              let(:target_priority) { create(:priority) }
              let(:other_priority) { work_package.priority }
              let(:priority_link) { api_v3_paths.priority target_priority.id }
              let(:other_priority_link) { api_v3_paths.priority other_priority.id }
              let(:priority_parameter) { { _links: { priority: { href: priority_link } } } }
              let(:params) { valid_params.merge(priority_parameter) }

              describe "allowed values" do
                before do
                  other_priority
                end

                include_context "with post request"

                it "lists the priorities" do
                  expect(subject.body).to be_json_eql(priority_link.to_json)
                    .at_path("#{links_path}/allowedValues/1/href")
                  expect(subject.body).to be_json_eql(other_priority_link.to_json)
                    .at_path("#{links_path}/allowedValues/0/href")
                end
              end

              context "for valid priority" do
                include_context "with post request"

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package priority" do
                  expect(subject.body).to be_json_eql(priority_link.to_json).at_path(path)
                end
              end
            end

            describe "type" do
              let(:path) { "_embedded/payload/_links/type/href" }
              let(:links_path) { "_embedded/schema/type/_links" }
              let(:target_type) { create(:type, custom_fields: [cf_all]) }
              let(:other_type) { work_package.type }
              let(:type_link) { api_v3_paths.type target_type.id }
              let(:other_type_link) { api_v3_paths.type other_type.id }
              let(:type_parameter) { { _links: { type: { href: type_link } } } }
              let(:params) { valid_params.merge(type_parameter) }

              before do
                project.types << target_type # make sure we have a valid transition
              end

              describe "allowed values" do
                before do
                  other_type
                end

                include_context "with post request"

                it "lists the types" do
                  expect(subject.body).to be_json_eql(type_link.to_json)
                    .at_path("#{links_path}/allowedValues/1/href")
                  expect(subject.body).to be_json_eql(other_type_link.to_json)
                    .at_path("#{links_path}/allowedValues/0/href")
                end
              end

              context "for valid type" do
                include_context "with post request"

                it_behaves_like "valid payload"

                it_behaves_like "having no errors"

                it "responds with updated work package type" do
                  expect(subject.body).to be_json_eql(type_link.to_json).at_path(path)
                end
              end
            end

            describe "budget" do
              let(:path) { "_embedded/payload/_links/budget/href" }
              let(:links_path) { "_embedded/schema/budget/_links" }
              let(:target_budget) { create(:budget, project:) }
              let(:other_budget) { create(:budget, project:) }
              let(:budget_link) { api_v3_paths.budget target_budget.id }
              let(:budget_parameter) { { _links: { budget: { href: budget_link } } } }
              let(:params) { valid_params.merge(budget_parameter) }

              describe "allowed values" do
                before do
                  other_budget
                end

                include_context "with post request"

                it "lists the budgets" do
                  budgets = project.budgets

                  budgets.each_with_index do |budget, index|
                    expect(subject.body).to be_json_eql(api_v3_paths.budget(budget.id).to_json)
                                              .at_path("#{links_path}/allowedValues/#{index}/href")
                  end
                end
              end

              context "for valid budget" do
                include_context "with post request"

                it_behaves_like "having no errors"

                it "responds with updated work package budget" do
                  expect(subject.body).to be_json_eql(budget_link.to_json).at_path(path)
                end
              end

              context "for invalid budget" do
                let(:target_budget) { create(:budget) }

                include_context "with post request"

                it_behaves_like "having an error", "budget"

                it "responds with updated work package budget" do
                  expect(subject.body).to be_json_eql(budget_link.to_json).at_path(path)
                end
              end
            end

            describe "multiple errors" do
              let(:user_link) { api_v3_paths.user 4200 }
              let(:status_link) { api_v3_paths.status -1 }
              let(:links) do
                {
                  _links: {
                    status: { href: status_link },
                    assignee: { href: user_link },
                    responsible: { href: user_link }
                  }
                }
              end
              let(:params) { valid_params.merge(subject: nil).merge(links) }

              include_context "with post request"

              it_behaves_like "valid payload"

              it {
                expect(subject.body).to have_json_size(4).at_path("_embedded/validationErrors")
              }

              it { expect(subject.body).to have_json_path("_embedded/validationErrors/subject") }

              it { expect(subject.body).to have_json_path("_embedded/validationErrors/status") }

              it { expect(subject.body).to have_json_path("_embedded/validationErrors/assignee") }

              it {
                expect(subject.body).to have_json_path("_embedded/validationErrors/responsible")
              }
            end

            describe "formattable custom field set to nil" do
              let(:custom_field) do
                create(:work_package_custom_field, field_format: "text")
              end

              let(:cf_param) { { custom_field.attribute_name(:camel_case) => nil } }
              let(:params) { valid_params.merge(cf_param) }

              before do
                project.work_package_custom_fields << custom_field
                project.save!
                work_package.type.custom_fields << custom_field
                work_package.save!

                login_as(current_user)
                post post_path, (params ? params.to_json : nil), "CONTENT_TYPE" => "application/json"
              end

              it "responds with a valid body (Regression OP#37510)" do
                expect(last_response).to have_http_status(:ok)
              end
            end
          end
        end
      end
    end

    context "for user with assign version permissions" do
      let(:params) do
        {
          lockVersion: work_package.lock_version
        }
      end

      include_context "with post request" do
        let(:current_user) { authorized_assign_user }
      end

      subject { last_response.body }

      shared_examples_for "valid payload" do
        it { expect(last_response).to have_http_status(:ok) }

        it { is_expected.to have_json_path("_embedded/payload") }

        it { is_expected.to have_json_path("_embedded/payload/lockVersion") }

        it { is_expected.to have_json_path("_embedded/payload/_links/version") }

        it { is_expected.not_to have_json_path("_embedded/payload/subject") }
      end

      it_behaves_like "valid payload"

      it "denotes subject to not be writable" do
        expect(subject)
          .to be_json_eql(false)
          .at_path("_embedded/schema/subject/writable")
      end

      it "denotes version to be writable" do
        expect(subject)
          .to be_json_eql(true)
          .at_path("_embedded/schema/version/writable")
      end

      it "denotes custom_field to not be writable" do
        expect(subject)
          .to be_json_eql(false)
          .at_path("_embedded/schema/#{cf_all.attribute_name.camelcase(:lower)}/writable")
      end
    end
  end
end
