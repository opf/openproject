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

RSpec.describe WikiController, "rename parameters", type: :controller do
  shared_let(:project) { create(:project, :with_internal_wiki).tap(&:reload) }
  shared_let(:wiki) { project.wiki }
  shared_let(:existing_page) do
    create(:wiki_page, wiki:, title: "Original title", text: "Original body text")
  end

  let(:permissions) { %i[view_project view_wiki_pages edit_wiki_pages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  describe "PATCH #rename" do
    let(:params) do
      {
        project_id: project.identifier,
        id: existing_page.title,
        page: {
          title: "Renamed title",
          text: "Injected body text",
          journal_notes: "Injected note"
        }
      }
    end

    it "does not allow changing body content" do
      patch :rename, params: params

      expect(response).to redirect_to(action: "show", project_id: project.identifier, id: "renamed-title")
      expect(existing_page.reload.title).to eq("Renamed title")
      expect(existing_page.text).to eq("Original body text")
      expect(existing_page.journals.last.notes).to eq("")
    end
  end
end
