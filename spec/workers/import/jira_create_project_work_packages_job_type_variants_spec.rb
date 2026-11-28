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

RSpec.describe Import::JiraCreateProjectWorkPackagesJob, :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"

  let(:resolution_date_cf) { create(:wp_custom_field, name: "Resolution Date (2)", field_format: "datetime") }

  def stage_5_resolution_date_cf
    jira_import.update!(system_field_custom_fields: { "resolutiondate" => resolution_date_cf.id })
  end

  before do
    create_project_role
    create_project
    stage_5_resolution_date_cf
  end

  context "when the issue type matches an existing one" do
    let!(:bug_type) { create(:type, name: "Bug") }
    let(:default_form) { bug_type.default_variant.form_configuration }
    let(:default_workflow) { bug_type.default_variant.workflow }
    let(:jira_issue_payload) { super().tap { it["fields"]["resolutiondate"] = "2026-09-12T12:18:05.851+0000" } }

    it "adds the custom fields to a project-specific variant only" do
      expect { create_work_packages }.to change(TypeVariant, :count).by(1)

      work_package = WorkPackage.find("DPPP-6")
      type_variant = work_package.type_variant
      default_variant = bug_type.reload.default_variant

      expect(work_package.type).to eq(bug_type)
      expect(type_variant).to have_attributes(project: work_package.project, is_default_variant: false)
      expect(type_variant.custom_field_ids).to include(resolution_date_cf.id)
      expect(default_variant.custom_field_ids).not_to include(resolution_date_cf.id)
    end

    it "does not modify the type's default form and workflow" do
      expect { create_work_packages }
        .to(not_change { default_form.reload.stored_attribute_groups }
        .and(not_change { default_workflow.reload.status_transitions.ids }))
    end

    context "when the type does not allow project-specific variants" do
      let!(:bug_type) { create(:type, name: "Bug", allow_project_variants: false) }

      it "aborts without creating work packages and type variants" do
        expect { create_work_packages }
          .to raise_error(/allow project-specific/)
          .and not_change(WorkPackage, :count)
          .and not_change(TypeVariant, :count)
      end
    end
  end
end
