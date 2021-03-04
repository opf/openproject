#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::TextFormatting,
         'Document links',
         # Speeds up the spec by avoiding event mailers to be procssed
         with_settings: { notified_events: [] } do
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end

  shared_let(:project) do
    FactoryBot.create :project, enabled_module_names: %w[documents]
  end

  shared_let(:document) do
    FactoryBot.create :document, project: project, title: 'My document'
  end

  subject do
    ::OpenProject::TextFormatting::Renderer.format_text(text, only_path: true)
  end

  before do
    login_as user
  end

  let(:text) do
    <<~TEXT
      document##{document.id}

      document:"My document"
    TEXT
  end

  context 'when visible' do
    let(:role) { FactoryBot.create :role, permissions: %i[view_documents view_project] }
    let(:user) { FactoryBot.create :user, member_in_project: project, member_through_role: role }

    let(:expected) do
      <<~HTML
        <p class="op-uc-p">#{document_link}</p>

        <p class="op-uc-p">#{document_link}</p>
      HTML
    end

    let(:document_link) do
      link_to(
        'My document',
        { controller: '/documents', action: 'show', id: document.id, only_path: true },
        class: 'document op-uc-link'
      )
    end

    it 'renders the links' do
      expect(subject).to be_html_eql(expected)
    end
  end

  context 'when not visible' do
    let(:user) { FactoryBot.create :user }

    let(:expected) do
      <<~HTML
        <p class="op-uc-p">document##{document.id}</p>

        <p class="op-uc-p">document:"My document"</p>
      HTML
    end

    it 'renders the raw text' do
      expect(subject).to be_html_eql(expected)
    end
  end
end
