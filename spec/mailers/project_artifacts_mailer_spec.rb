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

require_relative "../spec_helper"

RSpec.describe ProjectArtifactsMailer do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:work_package) { build_stubbed(:work_package, project:) }

  describe "#creation_wizard_submitted" do
    subject(:mail) { described_class.creation_wizard_submitted(user, project, work_package) }

    before do
      allow(project).to receive(:project_creation_wizard_notification_text).and_return("Custom notification text")
      allow(work_package).to receive(:visible?).and_return(true)
    end

    it "has the correct subject" do
      expect(mail.subject)
        .to eq I18n.t("settings.project_initiation_request.status.submitted",
                      wizard_name: "Project creation wizard")
    end

    it "is sent to the user" do
      expect(mail.to)
        .to contain_exactly(user.mail)
    end

    it "sets the project header" do
      expect(mail["X-OpenProject-Project"].value)
        .to eq project.identifier
    end

    it "contains the project name in the body" do
      expect(mail.html_part.body.encoded)
        .to include(project.name)
    end

    it "contains the project URL in the body" do
      expect(mail.html_part.body.encoded)
        .to include("/projects/#{project.identifier}")
    end

    context "with notification text" do
      before do
        allow(project).to receive(:project_creation_wizard_notification_text)
          .and_return("Welcome to the project creation wizard")
      end

      it "includes the notification text in the body" do
        expect(mail.html_part.body.encoded)
          .to include("Welcome to the project creation wizard")
      end
    end

    context "with notification text referencing a work package" do
      shared_let(:persisted_project) { create(:project, identifier: "wizardproj") }
      shared_let(:persisted_user) { create(:admin) }
      shared_let(:referenced_wp) { create(:work_package, project: persisted_project) }

      subject(:mail) { described_class.creation_wizard_submitted(persisted_user, persisted_project, referenced_wp) }

      before do
        allow(persisted_project).to receive_messages(
          project_creation_wizard_notification_text: "see ##{referenced_wp.id}",
          project_creation_wizard_enabled?: false
        )
      end

      let(:rendered_html) do
        User.execute_as(persisted_user) { mail.html_part.body.encoded }
      end

      it "rewrites work-package links to absolute URLs",
         with_settings: { work_packages_identifier: "classic" } do
        expect(rendered_html).to match(%r{href="http[^"]*/work_packages/#{referenced_wp.id}"})
      end
    end

    context "with work package" do
      it "includes a link to the work package" do
        expect(mail.html_part.body.encoded)
          .to include("/projects/#{project.identifier}/work_packages")
      end

      it "includes the work package link text" do
        expect(mail.html_part.body.encoded)
          .to include(I18n.t("settings.project_initiation_request.status.submitted_button"))
      end
    end

    context "with creation wizard enabled" do
      before do
        allow(project).to receive_messages(
          project_creation_wizard_enabled?: true,
          project_creation_wizard_artifact_name: "project_initiation_request"
        )
      end

      it "includes a link to the creation wizard" do
        expect(mail.html_part.body.encoded)
          .to include("/projects/#{project.identifier}/creation_wizard")
      end

      it "includes the wizard status button text" do
        expect(mail.html_part.body.encoded)
          .to include(I18n.t("settings.project_initiation_request.wizard_status_button.project_initiation_request"))
      end
    end

    context "with creation wizard disabled" do
      before do
        allow(project).to receive(:project_creation_wizard_enabled?).and_return(false)
      end

      it "does not include the wizard link" do
        expect(mail.html_part.body.encoded)
          .not_to include("/projects/#{project.identifier}/creation_wizard")
      end
    end

    describe "text part" do
      it "contains the project name" do
        expect(mail.text_part.body.encoded)
          .to include(project.name)
      end

      it "contains the project URL" do
        expect(mail.text_part.body.encoded)
          .to include("/projects/#{project.identifier}")
      end

      it "strips HTML tags from notification text" do
        allow(project).to receive(:project_creation_wizard_notification_text)
          .and_return("<strong>Bold text</strong>")

        expect(mail.text_part.body.encoded)
          .to include("Bold text")
        expect(mail.text_part.body.encoded)
          .not_to include("<strong>")
      end
    end
  end
end
