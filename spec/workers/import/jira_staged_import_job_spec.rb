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

RSpec.describe Import::JiraStagedImportJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  let(:batch) { instance_double(GoodJob::Batch, properties: { jira_import_id: jira_import.id, stage: }) }

  def run_stage
    described_class.perform_now(batch, { event: :success })
  end

  before { allow(batch).to receive(:enqueue).and_yield }

  describe "the stage building the import-wide prerequisites" do
    let(:stage) { 4 }

    # The custom fields have to exist before the per-project jobs fan out: each of those rebuilds
    # the registry, and creating the fields once up front keeps the per-project runs to a lookup.
    it "enqueues the project role and the custom fields job" do
      run_stage

      expect(batch).to have_received(:enqueue).with(stage: 5)
      expect(Import::JiraCreateProjectRoleJob).to have_been_enqueued.with(jira_import.id)
      expect(Import::JiraCreateCustomFieldsJob).to have_been_enqueued.with(jira_import.id)
    end
  end

  describe "the stage creating the projects" do
    let(:stage) { 5 }
    let!(:jira_project) do
      create(:jira_project, jira_import:, origin_id: "10012",
                            payload: { "id" => "10012", "key" => "DPPP", "name" => "Demo project" })
    end

    before { jira_import.update!(projects: [{ "id" => "10012", "key" => "DPPP", "name" => "Demo project" }]) }

    it "enqueues one project job per selected project" do
      run_stage

      expect(batch).to have_received(:enqueue).with(stage: 6)
      expect(Import::JiraCreateProjectJob).to have_been_enqueued.with(jira_import.id, jira_project.id)
    end
  end

  describe "the final stage" do
    let(:stage) { 8 }

    before { allow(batch).to receive(:enqueue) }

    it "marks the import as imported" do
      allow(jira_import).to receive(:transition_to!)
      allow(Import::JiraImport).to receive(:find).with(jira_import.id).and_return(jira_import)

      run_stage

      expect(jira_import).to have_received(:transition_to!).with(:imported)
    end
  end
end
