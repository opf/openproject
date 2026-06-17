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

require "rails_helper"

RSpec.describe Backlogs::SprintFormComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }

  let(:base_errors) { ["Sprint failed"] }
  let(:current_user) { create(:admin) }
  let(:component) { described_class.new(sprint:, project:, current_user:, base_errors:) }

  subject(:rendered_component) do
    render_inline(component)
  end

  it "exposes the sprint" do
    expect(component.sprint).to eq(sprint)
  end

  it "exposes base errors" do
    expect(component.base_errors).to eq(base_errors)
  end

  it "renders the form" do
    expect(rendered_component).to have_css("form##{described_class::FORM_ID}")
  end

  it "renders base errors" do
    expect(rendered_component).to have_text("Sprint failed")
  end

  describe "goal field" do
    context "when the sprint is not shared" do
      it "renders the goal text field" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:goal))
      end

      it "renders the goal text field under the goal command param" do
        expect(rendered_component).to have_field("sprint[goal][text]")
      end

      it "does not render the goal section separator" do
        expect(rendered_component).to have_no_css(".border-top.color-border-muted")
      end

      it "does not render the shared sprint banner" do
        expect(rendered_component).to have_no_text("This is a shared sprint")
      end

      it "does not render the project suffix on the label" do
        expect(rendered_component).to have_no_field(
          I18n.t("backlogs.sprint_form.goal_for_this_project_label", attribute: Sprint.human_attribute_name(:goal))
        )
      end
    end

    context "when a goal exists" do
      before do
        create(:sprint_goal, sprint:, project:, text: "Ship dashboard")
      end

      it "renders the goal value" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:goal), with: "Ship dashboard")
      end
    end
  end

  describe "shared sprint" do
    let(:sharing_project) { create(:project) }
    let(:sprint) { create(:sprint, project: sharing_project) }
    let(:role_with_perm) { create(:project_role, permissions: %i[view_sprints create_sprints]) }
    let(:role_without_perm) { create(:project_role, permissions: %i[view_sprints]) }

    context "when user has create_sprints in both projects" do
      let(:current_user) do
        create(:user,
               member_with_roles: { project => role_with_perm, sharing_project => role_with_perm })
      end

      it "renders the info banner" do
        expect(rendered_component).to have_text(
          I18n.t("backlogs.sprint_form_component.shared_sprint_info_banner")
        )
      end

      it "renders the goal label with project suffix" do
        expect(rendered_component).to have_field(
          I18n.t("backlogs.sprint_form.goal_for_this_project_label", attribute: Sprint.human_attribute_name(:goal))
        )
      end

      it "renders the goal caption" do
        expect(rendered_component).to have_text(I18n.t("backlogs.sprint_form.goal_caption"))
      end

      it "renders the goal section separator" do
        expect(rendered_component).to have_css(".border-top.color-border-muted", count: 1)
      end

      it "renders all fields as active" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:name), disabled: false)
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:goal), disabled: false)
      end
    end

    context "when user has create_sprints only in the sharing project" do
      let(:current_user) do
        create(:user,
               member_with_roles: { project => role_without_perm, sharing_project => role_with_perm })
      end

      it "renders the info banner" do
        expect(rendered_component).to have_text(
          I18n.t("backlogs.sprint_form_component.shared_sprint_info_banner")
        )
      end

      it "renders the goal field as disabled" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:goal), disabled: true)
      end

      it "renders the name field as active" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:name), disabled: false)
      end
    end

    context "when user has create_sprints only in the current project" do
      let(:current_user) do
        create(:user,
               member_with_roles: { project => role_with_perm, sharing_project => role_without_perm })
      end

      it "renders the warning banner" do
        expect(rendered_component).to have_text(
          I18n.t("backlogs.sprint_form_component.shared_sprint_warning_banner")
        )
      end

      it "renders the name field as disabled" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:name), disabled: true)
      end

      it "does not autofocus the disabled name field" do
        expect(rendered_component).to have_no_css('input[name="sprint[name]"][disabled][autofocus]')
      end

      it "renders duration as readonly but not disabled" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:duration), readonly: true, disabled: false)
      end

      it "renders the goal field as active" do
        expect(rendered_component).to have_field(Sprint.human_attribute_name(:goal), disabled: false)
      end
    end
  end
end
