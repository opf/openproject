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

RSpec.describe Projects::CreationWizardStatusComponent, type: :component do
  include ApplicationHelper
  include ProjectsHelper
  include Rails.application.routes.url_helpers

  let(:current_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project, project_creation_wizard_enabled:, project_creation_wizard_artifact_work_package_id:) }
  let(:project_creation_wizard_enabled) { true }
  let(:project_creation_wizard_artifact_work_package_id) { nil }
  let(:wizard_name) { "Project creation wizard" }

  subject(:component) { described_class.new(project:, current_user:) }

  describe "#render?" do
    context "when project_creation_wizard_enabled is false" do
      let(:project_creation_wizard_enabled) { false }

      it "returns false" do
        expect(component.render?).to be false
      end

      it "does not render the component" do
        rendered = render_inline(component)
        expect(rendered.to_s).to be_empty
      end
    end

    context "when project_creation_wizard_enabled is true" do
      let(:project_creation_wizard_enabled) { true }

      context "when artifact_id is present" do
        let(:project_creation_wizard_artifact_work_package_id) { 123 }

        before do
          allow(WorkPackage).to receive_message_chain(:visible, :find_by).with(id: 123).and_return(nil) # rubocop:disable RSpec/MessageChain
        end

        context "when user has view_work_packages permission" do
          before do
            allow(current_user).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(true)
          end

          it "returns true" do
            expect(component.render?).to be true
          end
        end

        context "when user does not have view_work_packages permission" do
          before do
            allow(current_user).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(false)
          end

          it "returns false" do
            expect(component.render?).to be false
          end

          it "does not render the component" do
            rendered = render_inline(component)
            expect(rendered.to_s).to be_empty
          end
        end
      end

      context "when artifact_id is not present" do
        let(:project_creation_wizard_artifact_work_package_id) { nil }

        context "when user has edit_project_attributes permission" do
          before do
            allow(current_user).to receive(:allowed_in_project?).with(:edit_project_attributes, project).and_return(true)
          end

          it "returns true" do
            expect(component.render?).to be true
          end
        end

        context "when user does not have edit_project_attributes permission" do
          before do
            allow(current_user).to receive(:allowed_in_project?).with(:edit_project_attributes, project).and_return(false)
          end

          it "returns false" do
            expect(component.render?).to be false
          end

          it "does not render the component" do
            rendered = render_inline(component)
            expect(rendered.to_s).to be_empty
          end
        end
      end
    end
  end

  describe "rendered status text" do
    context "when artifact_id is not present" do
      let(:project_creation_wizard_artifact_work_package_id) { nil }

      before do
        allow(current_user).to receive(:allowed_in_project?).with(:edit_project_attributes, project).and_return(true)
      end

      it "renders not_completed status text" do
        rendered = render_inline(component)
        expected_text = I18n.t("settings.project_initiation_request.status.not_completed", wizard_name:)
        expect(rendered.text).to include(expected_text)
      end
    end

    context "when artifact_id is present" do
      let(:project_creation_wizard_artifact_work_package_id) { 123 }

      before do
        allow(current_user).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(true)
        allow(WorkPackage).to receive_message_chain(:visible, :find_by).with(id: 123).and_return(nil) # rubocop:disable RSpec/MessageChain
      end

      it "renders submitted status text" do
        rendered = render_inline(component)
        expected_text = I18n.t("settings.project_initiation_request.status.submitted", wizard_name:)
        expect(rendered.text).to include(expected_text)
      end
    end
  end

  describe "rendered status explanation" do
    context "when artifact_id is not present" do
      let(:project_creation_wizard_artifact_work_package_id) { nil }

      before do
        allow(current_user).to receive(:allowed_in_project?).with(:edit_project_attributes, project).and_return(true)
      end

      it "renders not_completed_description" do
        rendered = render_inline(component)
        expected_text = I18n.t("settings.project_initiation_request.status.not_completed_description")
        expect(rendered.text).to include(expected_text)
      end

      it "renders a button linking to the project creation wizard" do
        rendered = render_inline(component)
        expect(rendered).to have_link(href: project_creation_wizard_path(project))
      end
    end

    context "when artifact_work_package is found" do
      let(:project_creation_wizard_artifact_work_package_id) { 123 }
      let(:work_package) { build_stubbed(:work_package, id: 123) }

      before do
        allow(current_user).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(true)
        allow(WorkPackage).to receive_message_chain(:visible, :find_by).with(id: 123).and_return(work_package) # rubocop:disable RSpec/MessageChain
      end

      it "renders submitted_description" do
        rendered = render_inline(component)
        expected_text = I18n.t("settings.project_initiation_request.status.submitted_description")
        expect(rendered.text).to include(expected_text)
      end

      it "sets artifact_work_package" do
        expect(component.artifact_work_package).to eq(work_package)
      end

      it "renders a button linking to the work package" do
        rendered = render_inline(component)
        expect(rendered).to have_link(href: project_work_packages_path(project, work_package))
      end
    end

    context "when artifact_id is present but work package is not visible" do
      let(:project_creation_wizard_artifact_work_package_id) { 123 }

      before do
        allow(current_user).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(true)
      end

      it "does not render submitted_description" do
        rendered = render_inline(component)
        submitted_text = I18n.t("settings.project_initiation_request.status.submitted_description")
        expect(rendered.text).not_to include(submitted_text)
      end

      it "sets artifact_work_package to nil" do
        expect(component.artifact_work_package).to be_nil
      end

      it "does not render any button" do
        rendered = render_inline(component)
        expect(rendered).to have_no_link(href: project_creation_wizard_path(project))
        expect(rendered).to have_no_css("a[href*='work_packages']")
      end
    end
  end

  describe "initialization" do
    it "sets project" do
      expect(component.project).to eq(project)
    end

    it "sets current_user" do
      expect(component.current_user).to eq(current_user)
    end

    it "sets artifact_id from project" do
      expect(component.artifact_id).to eq(project_creation_wizard_artifact_work_package_id)
    end

    context "when current_user is not provided" do
      subject(:component) { described_class.new(project:) }

      before do
        allow(User).to receive(:current).and_return(current_user)
      end

      it "defaults to User.current" do
        expect(component.current_user).to eq(current_user)
      end
    end
  end
end
