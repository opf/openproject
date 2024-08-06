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

RSpec.describe OpenProject::TextFormatting,
               "Meeting links" do
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end

  shared_let(:project) do
    create(:project, enabled_module_names: %w[meetings])
  end

  shared_let(:meeting) do
    create(:meeting, project:, title: "Monthly coordination")
  end

  subject do
    OpenProject::TextFormatting::Renderer.format_text(text, only_path: true)
  end

  before do
    login_as user
  end

  let(:text) do
    <<~TEXT
      meeting##{meeting.id}

      meeting:"monthly coordination"

      meeting:"Monthly coordination"
    TEXT
  end

  context "when visible" do
    let(:role) { create(:project_role, permissions: %i[view_meetings view_project]) }
    let(:user) { create(:user, member_with_roles: { project => role }) }

    let(:expected) do
      <<~HTML
        <p class="op-uc-p">#{meeting_link}</p>

        <p class="op-uc-p">#{meeting_link}</p>

        <p class="op-uc-p">#{meeting_link}</p>
      HTML
    end

    let(:meeting_link) do
      link_to(
        "Monthly coordination",
        { controller: "/meetings", action: "show", id: meeting.id, only_path: true },
        class: "meeting op-uc-link",
        target: "_top"
      )
    end

    it "renders the links" do
      expect(subject).to be_html_eql(expected)
    end
  end

  context "when not visible" do
    let(:user) { create(:user) }

    let(:expected) do
      <<~HTML
        <p class="op-uc-p">meeting##{meeting.id}</p>

        <p class="op-uc-p">meeting:"monthly coordination"</p>

        <p class="op-uc-p">meeting:"Monthly coordination"</p>
      HTML
    end

    it "renders the raw text" do
      expect(subject).to be_html_eql(expected)
    end
  end
end
