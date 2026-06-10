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

RSpec.describe DocumentsMailer do
  let(:user) do
    create(:user, firstname: "Test", lastname: "User", mail: "test@test.com")
  end
  let(:project) { create(:project, name: "TestProject") }
  let(:document) do
    create(:document, project:, description: "Test Description", title: "Test Title")
  end
  let(:mail) { DocumentsMailer.document_added(user, document) }

  describe "document added-mail", with_settings: { host_name: "my.openproject.com" } do
    it "renders the subject" do
      expect(mail.subject).to eql "[TestProject] New document: Test Title"
    end

    it "renders the receivers mail" do
      expect(mail.to.count).to be 1
      expect(mail.to.first).to eql user.mail
    end

    it "renders the document-info into the body" do
      expect(mail.body.encoded).to match(document.description)
      expect(mail.body.encoded).to match(document.title)
    end

    it "renders the correct link to the document in every format" do
      contents = mail.parts.map { |p| p.body.to_s }

      expect(contents).to all include("http://my.openproject.com/documents/#{document.id}")
    end
  end

  describe "document description referencing a work package",
           with_settings: { host_name: "my.openproject.com" } do
    shared_let(:persisted_project) { create(:project, identifier: "docsproj") }
    shared_let(:persisted_user) { create(:admin) }
    shared_let(:referenced_wp) { create(:work_package, project: persisted_project) }
    shared_let(:document) do
      create(:document,
             project: persisted_project,
             title: "Doc Title",
             description: "see ##{referenced_wp.id}")
    end

    let(:html_body) do
      User.execute_as(persisted_user) do
        described_class.document_added(persisted_user, document).html_part.body.to_s
      end
    end

    context "with classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders the numeric reference as an absolute work-package link" do
        expect(html_body).to match(%r{href="http[^"]*/work_packages/#{referenced_wp.id}"})
      end
    end

    context "with semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before do
        referenced_wp.update_columns(identifier: "DOCSPROJ-1", sequence_number: 1)
      end

      it "renders the formatted_id in the html body" do
        expect(html_body).to include("DOCSPROJ-1")
      end
    end
  end
end
