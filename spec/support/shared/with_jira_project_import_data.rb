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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Fixture graph and stage runners shared by the specs of the per-project import jobs.
# The jobs run one after another and depend on each other's output, so specs that assert on
# a later stage have to run the earlier ones too.
RSpec.shared_context "with jira project import data" do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }

  let(:jira_project_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/project.json").read) }
  let(:jira_user_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/user.json").read) }

  let(:jira_project_id) { jira_project_payload.fetch("id") }
  let(:jira_project_key) { jira_project_payload.fetch("key") }
  let(:jira_project_name) { jira_project_payload.fetch("name") }
  let(:jira_project_keys) { jira_project_payload.fetch("projectKeys") }

  let(:jira_import) do
    create(:jira_import, jira:, author:,
                         projects: [{ "id" => jira_project_id, "key" => jira_project_key, "name" => jira_project_name }])
  end

  let!(:jira_project) do
    create(:jira_project,
           jira_import:,
           origin_id: jira_project_id,
           payload: jira_project_payload)
  end

  let!(:default_status) { create(:default_status) }

  def create_project_role
    Import::JiraCreateProjectRoleJob.perform_now(jira_import.id)
  end

  def create_project
    Import::JiraCreateProjectJob.perform_now(jira_import.id, jira_project.id)
  end

  def create_work_packages
    Import::JiraCreateProjectWorkPackagesJob.perform_now(jira_import.id, jira_project.id)
  end

  def create_work_package_attachments
    Import::JiraCreateProjectWorkPackageAttachmentsJob.perform_now(jira_import.id, jira_project.id)
  end

  # Runs every per-project stage of the import in the order Import::JiraStagedImportJob enqueues them.
  def import_project
    create_project_role
    create_project
    create_work_packages
    create_work_package_attachments
  end
end

# The single demo issue from spec/fixtures/import/jira/issue.json together with every Jira-side
# entity it references.
RSpec.shared_context "with a jira demo issue" do
  include_context "with jira project import data"

  let(:jira_issue_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/issue.json").read) }

  let!(:jira_issue) do
    create(:jira_issue,
           jira_import:,
           origin_id: "10405",
           jira_project:,
           payload: jira_issue_payload)
  end

  let!(:jira_issue_type) do
    create(:jira_issue_type,
           jira_import:,
           origin_id: "10004",
           payload: { "id" => "10004", "name" => "Bug" })
  end

  let!(:jira_status) do
    create(:jira_status,
           jira_import:,
           origin_id: "3",
           payload: { "id" => "3", "name" => "In Progress" })
  end

  let!(:jira_priority) do
    create(:jira_priority,
           jira_import:,
           origin_id: "1",
           payload: { "id" => "1", "name" => "Highest" })
  end

  let!(:jira_user) do
    create(:jira_user,
           jira_import:,
           origin_id: "JIRAUSER10000",
           payload: jira_user_payload)
  end

  let!(:op_user) { create(:user, login: "p.balashou", mail: "p.balashou@openproject.com") }

  let!(:jira_user_reference) do
    create(:jira_open_project_reference,
           jira_import:,
           jira_entity_class: "Import::JiraUser",
           jira_entity_id: jira_user.id.to_s,
           op_entity_class: "User",
           op_entity_id: op_user.id.to_s)
  end
end
