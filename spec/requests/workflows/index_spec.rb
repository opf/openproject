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

RSpec.describe "Workflows index", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:milestone) { create(:type, name: "Milestone") }

  shared_let(:bug_base) { bug.default_variant }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }

  shared_let(:on_bug) { create(:project, name: "OnBug", types: [bug]) }
  shared_let(:on_task) { create(:project, name: "OnTask", types: [task]) }

  shared_let(:shared_workflow) { bug_base.workflow }

  before_all do
    [task, milestone].each do |type|
      orphaned = type.default_variant.workflow
      type.default_variant.update!(workflow: shared_workflow)
      orphaned.reload.destroy!
    end

    shared_workflow.update!(name: "Standard flow")
  end

  before { login_as admin }

  def type_filter(*types)
    values = types.map { %("#{it.id}") }
    rendered = values.one? ? values.first : "[#{values.join(',')}]"

    "type_id = #{rendered}"
  end

  def row_for(name)
    page.find(".Box-row", text: /#{Regexp.escape(name)}/)
  end

  it "lists one row per workflow, counting what each one reaches" do
    get workflows_path

    expect(response).to have_http_status(:ok)

    row = row_for("Standard flow")
    expect(row).to have_css(".types_and_variants", text: "3 types (including 1 variant)")
    expect(row).to have_css(".projects", text: I18n.t("workflows.index.projects_count", count: 2))
  end

  it "names the workflow and its description in the main column" do
    shared_workflow.update!(description: "Everything the team agreed on")

    get workflows_path

    main = ".op-border-box-grid__row-item--main-column"
    expect(page).to have_css(main, text: "Standard flow")
    expect(page).to have_css(main, text: "Everything the team agreed on")
  end

  it "dashes every count for a workflow nothing references" do
    create(:named_workflow, name: "Spare flow")

    get workflows_path

    row = row_for("Spare flow")
    expect(row).to have_css(".types_and_variants", text: "-")
    expect(row).to have_css(".roles", text: "-")
    expect(row).to have_css(".projects", text: "-")
  end

  it "counts the projects a workflow is active in" do
    3.times { |n| create(:project, name: "Extra #{n}", types: [milestone]) }

    get workflows_path

    row = row_for("Standard flow")
    expect(row).to have_css(".projects", text: I18n.t("workflows.index.projects_count", count: 5))
    expect(row).to have_no_css(".projects a")
  end

  it "marks a workflow a project owns with that project" do
    owner = create(:project, name: "Bookshop")
    create(:project_owned_workflow, project: owner, name: "Bookshop flow")

    get workflows_path

    row = row_for("Bookshop flow")
    expect(row).to have_text("Created in Bookshop")
    expect(row).to have_link("Bookshop", href: project_settings_work_packages_types_path(owner))
  end

  it "leaves a global workflow unmarked" do
    get workflows_path

    expect(row_for("Standard flow")).to have_no_text("Created in")
  end

  describe "filtering" do
    it "answers a turbo stream replacing the results" do
      create(:named_workflow, name: "Spare flow")

      get workflows_path(filters: %(name ~ "standard")), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("workflows-index-results-component")
      expect(response.body).to include("Standard flow")
      expect(response.body).not_to include("Spare flow")
    end

    it "matches the workflow name" do
      create(:named_workflow, name: "Spare flow")

      get workflows_path(filters: %(name ~ "standard"))

      expect(page).to have_text("Standard flow")
      expect(page).to have_no_text("Spare flow")
    end

    it "matches the description" do
      shared_workflow.update!(description: "Agreed by the whole team")

      get workflows_path(filters: %(name ~ "whole team"))

      expect(page).to have_text("Standard flow")
    end

    it "finds a workflow through a type that only uses it" do
      spare = create(:named_workflow, name: "Spare flow")
      create(:type, name: "Phase").default_variant.update!(workflow: spare)

      get workflows_path(filters: type_filter(milestone))

      expect(page).to have_text("Standard flow")
      expect(page).to have_no_text("Spare flow")
    end

    it "matches projects a type using the workflow is active in" do
      spare = create(:named_workflow, name: "Spare flow")
      phase = create(:type, name: "Phase")
      phase.default_variant.update!(workflow: spare)
      create(:project, name: "OnPhase", types: [phase])

      get workflows_path(filters: %(project_id = "#{on_task.id}"))

      expect(page).to have_text("Standard flow")
      expect(page).to have_no_text("Spare flow")
    end

    it "finds the workflows a project owns as well as the ones it uses" do
      owner = create(:project, name: "Bookshop")
      create(:project_owned_workflow, project: owner, name: "Bookshop flow")
      create(:named_workflow, name: "Spare flow")

      get workflows_path(filters: %(project_id = "#{owner.id}"))

      expect(page).to have_text("Bookshop flow")
      expect(page).to have_no_text("Spare flow")
    end

    it "renders the blank slate when nothing matches" do
      get workflows_path(filters: %(name ~ "nothing here"))

      expect(page).to have_text(I18n.t("workflows.index.blank_slate.filtered_title"))
    end
  end

  it "denies non-admins" do
    login_as create(:user)

    get workflows_path

    expect(response).not_to have_http_status(:ok)
  end
end
