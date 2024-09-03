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

RSpec.describe ApplicationHelper do
  include ApplicationHelper
  include ActionView::Helpers
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  describe ".format_text" do
    let(:project) { create(:valid_project) }
    let(:identifier) { project.identifier }
    let(:role) do
      create(:project_role, permissions: %i[
               view_work_packages edit_work_packages view_documents browse_repository view_changesets view_wiki_pages
             ])
    end
    let(:project_member) do
      create(:user, member_with_roles: { project => role })
    end
    let(:document) do
      create(:document,
             title: "Test document",
             project:)
    end

    before do
      @project = project
      allow(User).to receive(:current).and_return project_member
    end

    after do
      allow(User).to receive(:current).and_call_original
    end

    context "Simple Document links" do
      let(:document_link) do
        link_to("Test document",
                { controller: "documents", action: "show", id: document.id },
                class: "document op-uc-link",
                target: "_top")
      end

      context "Plain link" do
        subject { format_text("document##{document.id}") }

        it { is_expected.to be_html_eql("<p class=\"op-uc-p\">#{document_link}</p>") }
      end

      context "Link with document name" do
        subject { format_text("document##{document.id}") }

        it { is_expected.to be_html_eql("<p class=\"op-uc-p\">#{document_link}</p>") }
      end

      context "Escaping plain link" do
        subject { format_text("!document##{document.id}") }

        it { is_expected.to be_html_eql("<p class=\"op-uc-p\">document##{document.id}</p>") }
      end

      context "Escaping link with document name" do
        subject { format_text('!document:"Test document"') }

        it { is_expected.to be_html_eql('<p class="op-uc-p">document:"Test document"</p>') }
      end
    end

    context "Cross-Project Document Links" do
      let(:the_other_project) { create(:valid_project) }

      context "By name without project" do
        subject { format_text("document:\"#{document.title}\"", project: the_other_project) }

        it { is_expected.to be_html_eql('<p class="op-uc-p">document:"Test document"</p>') }
      end

      context "By id and given project" do
        subject { format_text("#{identifier}:document##{document.id}", project: the_other_project) }

        it {
          expect(subject).to be_html_eql("<p class=\"op-uc-p\"><a class=\"document op-uc-link\" href=\"/documents/#{document.id}\" target=\"_top\">Test document</a></p>")
        }
      end

      context "By name and given project" do
        subject { format_text("#{identifier}:document:\"#{document.title}\"", project: the_other_project) }

        it {
          expect(subject).to be_html_eql("<p class=\"op-uc-p\"><a class=\"document op-uc-link\" href=\"/documents/#{document.id}\" target=\"_top\">Test document</a></p>")
        }
      end

      context "Invalid link" do
        subject { format_text("invalid:document:\"Test document\"", project: the_other_project) }

        it { is_expected.to be_html_eql('<p class="op-uc-p">invalid:document:"Test document"</p>') }
      end
    end
  end
end
