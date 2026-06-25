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
require "rack/test"

RSpec.describe "API v3 Work package resource",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) do
    create(:project, identifier: "test_project", public: false)
  end
  shared_let(:type) { project.types.first }

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[add_work_packages view_project view_work_packages] + extra_permissions }
  let(:extra_permissions) { [] }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  describe "POST /api/v3/work_packages" do
    let(:path) { api_v3_paths.work_packages }
    let(:other_user) { nil }
    let(:status) { build(:status, is_default: true) }
    let(:priority) { build(:priority, is_default: true) }
    let(:parameters) do
      {
        subject: "new work packages",
        _links: {
          type: {
            href: api_v3_paths.type(type.id)
          },
          project: {
            href: api_v3_paths.project(project.id)
          }
        }
      }
    end
    let(:project_storage) { nil }

    before do
      status.save!
      priority.save!
      other_user
      project_storage

      perform_enqueued_jobs do
        post path, parameters.to_json
      end
    end

    describe "notifications" do
      let(:other_user) do
        create(:user,
               member_with_permissions: { project => permissions },
               notification_settings: [
                 build(:notification_setting,
                       work_package_created: true)
               ])
      end

      it "creates a notification" do
        expect(Notification.where(recipient: other_user, resource: WorkPackage.last))
          .to exist
      end

      context "without notifications" do
        let(:path) { "#{api_v3_paths.work_packages}?notify=false" }

        it "creates no notification" do
          expect(Notification)
            .not_to exist
        end
      end

      context "with notifications" do
        let(:path) { "#{api_v3_paths.work_packages}?notify=true" }

        it "creates a notification" do
          expect(Notification.where(recipient: other_user, resource: WorkPackage.last))
            .to exist
        end
      end
    end

    it "returns Created(201)" do
      expect(last_response).to have_http_status(:created)
    end

    it "creates a work package" do
      expect(WorkPackage.count).to eq(1)
    end

    it "uses the given parameters" do
      expect(WorkPackage.first.subject).to eq(parameters[:subject])
    end

    it "is associated with the provided project" do
      expect(WorkPackage.first.project).to eq(project)
    end

    it "is associated with the provided type" do
      expect(WorkPackage.first.type).to eq(type)
    end

    context "without any permissions" do
      let(:current_user) { create(:user) }

      it "hides the endpoint" do
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "when view_project permission is enabled" do
      # Note that this just removes the add_work_packages permission
      # view_project is actually provided by being a member of the project
      let(:permissions) { [:view_project] }

      it "points out the missing permission" do
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "with empty parameters" do
      let(:parameters) { {} }

      it_behaves_like "multiple errors", 422

      it "does not create a work package" do
        expect(WorkPackage.count).to eq(0)
      end
    end

    context "with bogus parameters" do
      let(:parameters) do
        {
          bogus: "bogus",
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Subject can't be blank" }
      end

      it "does not create a work package" do
        expect(WorkPackage.count).to eq(0)
      end
    end

    describe "scheduleManually parameter" do
      let(:created_work_package) { WorkPackage.find_by(subject: "new work packages") }

      context "when true" do
        # mind the () for the super call, those are required in rspec's super
        let(:parameters) { super().merge(scheduleManually: true) }

        it "sets the scheduling mode to manual (schedule_manually: true)" do
          expect(created_work_package.schedule_manually).to be true
        end

        context "when also being the first child of a manually scheduled parent" do
          let(:extra_permissions) { %i[manage_subtasks] }
          let(:parent) do
            create(:work_package, project:,
                                  subject: "parent",
                                  schedule_manually: true,
                                  start_date: Date.new(2025, 1, 1),
                                  due_date: Date.new(2025, 1, 31))
          end
          let(:parameters) do
            super().deep_merge(
              startDate: nil,
              dueDate: nil,
              _links: {
                parent: {
                  href: api_v3_paths.work_package(parent.id)
                }
              }
            )
          end

          it "changes the scheduling mode of the parent work package to automatic " \
             "and sets its dates to match the child's dates" do
            expect(created_work_package.parent).to eq(parent.reload)
            expect(created_work_package.parent.schedule_manually).to be false
            expect(created_work_package.parent.start_date).to be_nil
            expect(created_work_package.parent.due_date).to be_nil
          end
        end
      end

      context "when false" do
        let(:parameters) do
          super().merge(scheduleManually: false)
        end

        context "when the created work package has an indirect predecessor" do
          let(:extra_permissions) { %i[manage_subtasks] }
          let(:predecessor) { create(:work_package, project:, subject: "predecessor") }
          let(:parent) do
            create(:work_package, project:,
                                  subject: "parent",
                                  schedule_manually: false).tap do |parent|
              create(:follows_relation, predecessor:, successor: parent)
            end
          end
          let(:parameters) do
            super().deep_merge(
              _links: {
                parent: {
                  href: api_v3_paths.work_package(parent.id)
                }
              }
            )
          end

          it "sets the scheduling mode to automatic as requested (schedule_manually: false)" do
            expect(created_work_package.schedule_manually).to be false
          end
        end

        context "when the work package has no direct or indirect predecessors and no children" do
          it_behaves_like "error response",
                          422,
                          "PropertyConstraintViolation",
                          I18n.t("activerecord.errors.models.work_package.attributes." \
                                 "schedule_manually.cannot_be_automatically_scheduled")
        end
      end

      context "when absent" do
        it "sets the scheduling mode to manual (schedule_manually: true, the default)" do
          expect(created_work_package.schedule_manually).to be true
        end
      end
    end

    context "with invalid value" do
      let(:parameters) do
        {
          subject: nil,
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Subject can't be blank" }
      end

      it "does not create a work package" do
        expect(WorkPackage.count).to eq(0)
      end
    end

    describe "custom fields" do
      context "when the custom field is required" do
        shared_let(:required_custom_field) do
          create(:work_package_custom_field,
                 field_format: "string",
                 name: "Department",
                 is_required: true,
                 projects: [project],
                 types: [type])
        end

        context "when no custom field value is provided" do
          let(:parameters) do
            {
              subject: "new work package with CF",
              _links: {
                type: {
                  href: api_v3_paths.type(type.id)
                },
                project: {
                  href: api_v3_paths.project(project.id)
                }
              }
            }
          end

          it "responds with 422 and explains the custom field error" do
            expect(last_response).to have_http_status(:unprocessable_entity)

            expect(last_response.body)
              .to be_json_eql("Department can't be blank.".to_json)
              .at_path("message")
          end
        end

        context "when the custom field is provided but empty" do
          let(:parameters) do
            {
              subject: "new work package with CF",
              "customField#{required_custom_field.id}" => "",
              _links: {
                type: {
                  href: api_v3_paths.type(type.id)
                },
                project: {
                  href: api_v3_paths.project(project.id)
                }
              }
            }
          end

          it "responds with 422 and explains the custom field error" do
            expect(last_response).to have_http_status(:unprocessable_entity)

            expect(last_response.body)
              .to be_json_eql("Department can't be blank.".to_json)
              .at_path("message")
          end
        end

        context "when the custom field value is provided and valid" do
          let(:parameters) do
            {
              subject: "new work package with CF",
              "customField#{required_custom_field.id}" => "Engineering",
              _links: {
                type: {
                  href: api_v3_paths.type(type.id)
                },
                project: {
                  href: api_v3_paths.project(project.id)
                }
              }
            }
          end

          it "responds with 201" do
            expect(last_response).to have_http_status(:created)
          end

          it "returns the newly created work package" do
            expect(last_response.body)
              .to be_json_eql("WorkPackage".to_json)
              .at_path("_type")

            expect(last_response.body)
              .to be_json_eql("new work package with CF".to_json)
              .at_path("subject")
          end

          it "creates a work package with the custom field value" do
            work_package = WorkPackage.last
            expect(work_package.typed_custom_value_for(required_custom_field))
              .to eq("Engineering")
          end
        end
      end
    end

    context "when attachments are being claimed" do
      let(:attachment) { create(:attachment, container: nil, author: current_user) }
      let(:parameters) do
        {
          subject: "subject",
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
            attachments: [
              { href: api_v3_paths.attachment(attachment.id) }
            ]
          }
        }
      end

      it "creates the work package and assigns the attachments" do
        expect(WorkPackage.count).to eq(1)

        work_package = WorkPackage.last

        expect(work_package.attachments)
          .to match_array(attachment)
      end
    end

    context "when file links are being claimed" do
      let(:storage) { create(:nextcloud_storage) }
      let(:project_storage) { create(:project_storage, project:, storage:) }
      let(:file_link) do
        create(:file_link,
               container_id: nil,
               container_type: nil,
               storage:,
               creator: current_user)
      end
      let(:parameters) do
        {
          subject: "subject",
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
            fileLinks: [
              { href: api_v3_paths.file_link(file_link.id) }
            ]
          }
        }
      end
      let(:extra_permissions) { %i[view_file_links manage_file_links] }

      context "when user is not allowed to manage file links" do
        let(:extra_permissions) { %i[view_file_links] }

        it "does not create a work package and responds with an error" do
          expect(WorkPackage.count).to eq(0)
          expect(last_response.body).to be_json_eql(
            "urn:openproject-org:api:v3:errors:MissingPermission".to_json
          ).at_path("errorIdentifier")
        end
      end

      context "when there is no project storage for the file link's storage" do
        let(:project_storage) { create(:project_storage, project:) }

        it "does not create a work package and responds with an error" do
          expect(WorkPackage.count).to eq(0)
          expect(last_response.body).to be_json_eql(
            "urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json
          ).at_path("errorIdentifier")
        end
      end

      context "when user is allowed to manage file links" do
        it "creates a work package and assigns the file links" do
          expect(WorkPackage.count).to eq(1)
          work_package = WorkPackage.first
          expect(work_package.file_links).to eq([file_link])
          expect(work_package.file_links.first.container_type).to eq("WorkPackage")
          expect(last_response.body).to be_json_eql(
            api_v3_paths.file_links(work_package.id).to_json
          ).at_path("_links/fileLinks/href")
          expect(last_response.body).to have_json_path("_links/addFileLink")
        end
      end
    end
  end
end
