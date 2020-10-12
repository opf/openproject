#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ApplicationHelper do
  include ApplicationHelper
  include ActionView::Helpers
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers


  describe ".format_text"  do
    let(:project) { FactoryBot.create :valid_project }
    let(:identifier) { project.identifier }
    let(:role) {
      FactoryBot.create(:role, permissions: [
      :view_work_packages, :edit_work_packages, :view_documents, :browse_repository, :view_changesets, :view_wiki_pages
      ])
    }
    let(:project_member) {
      FactoryBot.create :user, member_in_project: project,
                                member_through_role: role
    }
    let(:document) {
      FactoryBot.create :document,
                                          title: 'Test document',
                                          project: project
    }

    before do
      @project = project
      allow(User).to receive(:current).and_return project_member
    end

    after do
      allow(User).to receive(:current).and_call_original
    end

    context "Simple Document links" do
      let(:document_link) {
        link_to('Test document',
                                     { controller: 'documents', action: 'show', id: document.id },
                                     class: 'document')
      }

      context "Plain link" do
        subject { format_text("document##{document.id}") }

        it { is_expected.to eq("<p>#{document_link}</p>") }
      end

      context "Link with document name" do
        subject { format_text("document##{document.id}") }

        it { is_expected.to eq("<p>#{document_link}</p>") }
      end

      context "Escaping plain link" do
        subject { format_text("!document##{document.id}") }

        it { is_expected.to eq("<p>document##{document.id}</p>") }
      end

      context "Escaping link with document name" do
        subject { format_text('!document:"Test document"') }

        it { is_expected.to eq('<p>document:"Test document"</p>') }
      end
    end

    context 'Cross-Project Document Links' do
      let(:the_other_project) { FactoryBot.create :valid_project }

      context "By name without project" do
        subject { format_text("document:\"#{document.title}\"", project: the_other_project) }

        it { is_expected.to eq('<p>document:"Test document"</p>') }
      end

      context "By id and given project" do
        subject { format_text("#{identifier}:document##{document.id}", project: the_other_project) }

        it { is_expected.to eq("<p><a class=\"document\" href=\"/documents/#{document.id}\">Test document</a></p>") }
      end

      context "By name and given project" do
        subject { format_text("#{identifier}:document:\"#{document.title}\"", project: the_other_project) }

        it { is_expected.to eq("<p><a class=\"document\" href=\"/documents/#{document.id}\">Test document</a></p>") }
      end

      context "Invalid link" do
        subject { format_text("invalid:document:\"Test document\"", project: the_other_project) }

        it { is_expected.to eq('<p>invalid:document:"Test document"</p>') }
      end
    end
  end
end
