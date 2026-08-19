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

require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples "work package contract" do
  create_shared_association_defaults_for_work_package_factory

  include_context "ModelContract shared context"
  shared_let(:persisted_type) { create(:type) }
  shared_let(:persisted_type_with_pattern) do
    create(:type, patterns: { subject: { blueprint: "{{type}} {{project_name}}", enabled: true } })
  end
  shared_let(:persisted_project) { create(:project, types: [persisted_type, persisted_type_with_pattern]) }
  shared_let(:persisted_other_project) { create(:project, types: [persisted_type]) }
  shared_let(:persisted_project_version) { create(:version, project: persisted_project) }
  shared_let(:persisted_other_project_version) { create(:version) }
  shared_let(:persisted_status) { create(:status) }
  shared_let(:persisted_priority) { create(:priority) }
  shared_let(:persisted_possible_assignee) do
    create(:user, member_with_permissions: { persisted_project => %i[view_work_packages work_package_assigned] })
  end
  shared_let(:persisted_non_member) { create(:user) }
  shared_let(:persisted_user_role) do
    create(:project_role, permissions: %i[view_work_packages])
  end
  shared_let(:persisted_project_phase_definition) { create(:project_phase_definition) }
  shared_let(:persisted_active_project_phase) do
    create(:project_phase, :active, project: persisted_project, definition: persisted_project_phase_definition)
  end
  shared_let(:persisted_inactive_project_phase) { create(:project_phase, :inactive, project: persisted_project) }

  shared_let(:persisted_user) do
    create(:user, member_with_roles: { persisted_project => persisted_user_role,
                                       persisted_other_project => persisted_user_role })
  end

  let(:other_user) { build_stubbed(:user) }

  subject(:contract) { described_class.new(work_package, user) }

  let(:validated_contract) do
    contract = subject
    contract.validate
    contract
  end

  before do
    if user.members.any?
      persisted_user_role.permissions = permissions
      persisted_user_role.save
    end
  end

  describe "validations" do
    context "when all attributes are valid" do
      it_behaves_like "contract is valid"
    end

    describe "subject" do
      context "when the type is set" do
        before do
          work_package.subject = "Allowed to change subject"
        end

        it_behaves_like "contract is valid"
      end

      context "when subject is blank and type does not auto-generate subject" do
        before do
          work_package.subject = ""
        end

        it_behaves_like "contract is invalid", subject: :blank
      end

      context "when the subject is changed and the type has an enabled replacement pattern for subject" do
        before do
          work_package.type = persisted_type_with_pattern
          work_package.subject = "Trying to change subject"
        end

        it_behaves_like "contract is invalid", subject: :error_readonly
      end

      context "when subject is blank and type auto-generates subject" do
        let(:type_with_pattern) do
          create(:type, patterns: { subject: { blueprint: "{{type}} {{project_name}}", enabled: true } })
        end

        before do
          # The type auto generates the subject.
          # Therefore, it is ok that when creating the work package, the subject is empty.
          # It will be set by the services before saving.
          # Setting subject is not allowed when auto generating (read-only), which is why the spec works around that.
          work_package.extend(OpenProject::ChangedBySystem)

          work_package.change_by_system do
            work_package.subject = ""
          end

          work_package.type = persisted_type_with_pattern
        end

        it_behaves_like "contract is valid"
      end

      context "when the type has a disabled replacement pattern for subject" do
        let(:type_with_disabled_pattern) do
          create(:type, patterns: { subject: { blueprint: "{{type}} {{project_name}}", enabled: false } }) do |type|
            work_package.project.types << type
          end
        end

        before do
          work_package.type = type_with_disabled_pattern
          work_package.subject = "Allowed to change subject"
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "assigned_to_id" do
      context "if the assigned user is a possible assignee" do
        before do
          work_package.assigned_to = persisted_possible_assignee
        end

        it_behaves_like "contract is valid"
      end

      context "if the assigned user is not a possible assignee" do
        before do
          work_package.assigned_to = persisted_non_member
        end

        it_behaves_like "contract is invalid",
                        assigned_to: I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                                            property: I18n.t("attributes.assignee"))
      end

      context "if the project is not set" do
        before do
          work_package.assigned_to = persisted_possible_assignee
          work_package.project = nil
        end

        it_behaves_like "contract is invalid",
                        # But not on assignee
                        project: :blank
      end
    end

    describe "responsible_id" do
      context "if the responsible user is a possible responsible" do
        before do
          work_package.responsible = persisted_possible_assignee
        end

        it_behaves_like "contract is valid"
      end

      context "if the assigned user is not a possible responsible" do
        before do
          work_package.responsible = persisted_non_member
        end

        it_behaves_like "contract is invalid",
                        responsible: I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                                            property: I18n.t("attributes.responsible"))
      end

      context "if the project is not set" do
        before do
          work_package.responsible = persisted_possible_assignee
          work_package.project = nil
        end

        it_behaves_like "contract is invalid",
                        # But not on responsible
                        project: :blank
      end
    end

    describe "remaining_hours" do
      context "when is not a parent" do
        context "when has not changed" do
          it_behaves_like "contract is valid"
        end

        context "when has changed" do
          before do
            work_package.remaining_hours = 10
          end

          it_behaves_like "contract is valid"
        end
      end
    end

    describe "version" do
      context "having full access" do
        context "with an assignable_version" do
          before do
            work_package.version = persisted_project_version
          end

          it_behaves_like "contract is valid"
        end

        context "with an unassignable_version" do
          before do
            work_package.version = persisted_other_project_version
          end

          it_behaves_like "contract is invalid", version_id: :inclusion
        end
      end

      context "without the necessary permission to change versions" do
        let(:permissions) { super() - %i[assign_versions] }

        before do
          work_package.version = persisted_project_version
        end

        it_behaves_like "contract is invalid", version_id: :error_readonly
      end
    end

    describe "ignore_non_working_days" do
      context "when not having children and scheduling manually" do
        before do
          work_package.ignore_non_working_days = !work_package.ignore_non_working_days
          work_package.schedule_manually = true
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "project_phase_definition" do
      let(:permissions) { super() + %i[view_project_phases] }

      before do
        work_package.project_phase_definition = persisted_project_phase_definition
      end

      it_behaves_like "contract is valid"

      context "without the necessary permission" do
        let(:permissions) { super() - %i[view_project_phases] }

        it_behaves_like "contract is invalid", project_phase_id: :error_readonly
      end

      context "without a project being set" do
        before do
          work_package.project = nil
        end

        it_behaves_like "contract is invalid",
                        # But not on project_phase_id
                        project: :blank
      end

      context "when assigning a definition not active in the project" do
        before do
          work_package.project_phase_definition = persisted_inactive_project_phase.definition
        end

        it_behaves_like "contract is invalid", project_phase_id: :inclusion
      end
    end
  end

  describe "#assignable_project_phases" do
    context "when project is not set" do
      before do
        work_package.project = nil
      end

      it "returns an empty array" do
        expect(contract.assignable_project_phases).to be_empty
      end
    end

    context "when project is set" do
      before do
        work_package.project = persisted_project
      end

      it "returns the phases active in the project" do
        expect(contract.assignable_project_phases).to contain_exactly(persisted_active_project_phase)
      end
    end
  end
end
