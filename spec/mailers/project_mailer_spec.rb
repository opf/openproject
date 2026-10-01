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

RSpec.describe ProjectMailer do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  describe "#project_created" do
    subject(:mail) { described_class.project_created(project, user:) }

    it "has a subject with the project name" do
      expect(mail.subject)
        .to eq I18n.t("projects.create.notification_email_subject", project_name: project.name)
    end

    it "is sent to the user" do
      expect(mail.to)
        .to contain_exactly(user.mail)
    end

    it "sets the project header" do
      expect(mail["X-OpenProject-Project"].value)
        .to eq project.identifier
    end

    it "sets the author header" do
      expect(mail["X-OpenProject-Author"].value)
        .to eq user.login
    end

    it "contains the project name in the body by default" do
      expect(mail.html_part.body.encoded)
        .to include(project.name)
    end

    context "with custom notification text" do
      before do
        allow(Setting).to receive(:new_project_notification_text).and_return("Some custom text")
      end

      it "includes the custom text" do
        expect(mail.html_part.body.encoded)
          .to include("Some custom text")
      end
    end

    context "with custom notification text referencing a work package" do
      shared_let(:persisted_project) { create(:project, identifier: "absurlproj") }
      shared_let(:persisted_user) { create(:admin) }
      shared_let(:referenced_wp) { create(:work_package, project: persisted_project) }

      subject(:mail) { described_class.project_created(persisted_project, user: persisted_user) }

      before do
        allow(Setting).to receive(:new_project_notification_text)
          .and_return("see ##{referenced_wp.id}")
      end

      let(:rendered_html) do
        User.execute_as(persisted_user) { mail.html_part.body.encoded }
      end

      it "rewrites work-package links to absolute URLs",
         with_settings: { work_packages_identifier: "classic" } do
        expect(rendered_html).to match(%r{href="http[^"]*/work_packages/#{referenced_wp.id}"})
      end
    end

    context "with the creation wizard enabled" do
      before do
        allow(project).to receive_messages(
          project_creation_wizard_enabled?: true,
          project_creation_wizard_artifact_name: "project_initiation_request"
        )
      end

      it "includes a link to the wizard" do
        expect(mail.html_part.body.encoded)
          .to include("/projects/#{project.identifier}/creation_wizard")
      end
    end

    context "with project creation wizard disabled" do
      before do
        allow(project).to receive_messages(
          project_creation_wizard_enabled?: false,
          project_creation_wizard_artifact_name: "project_initiation_request"
        )
      end

      it "does not include the wizard link" do
        expect(mail.html_part.body.encoded)
          .not_to include("/projects/#{project.identifier}/creation_wizard")
      end
    end
  end
end
