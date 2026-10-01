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

RSpec.describe "Permission explanations in the role form", type: :rails_request do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  let(:documentation_url) do
    OpenProject::Static::Links.url_for(:sysadmin_docs, :project_identifier_visibility)
  end
  let(:caution_text) do
    "can find out whether a project identifier is already taken"
  end

  describe "GET /roles/new" do
    before do
      get new_role_path
    end

    it "renders explanations that carry no link as plain text" do
      expect(response.body).to include(I18n.t(:permission_copy_projects_explanation))
    end

    # Both the global and the member permission list are rendered, the form only
    # toggles between them client-side.
    it "cautions about identifier enumeration for the project creation permissions" do
      expect(response.body.scan(caution_text).size).to eq(2)
    end

    it "links the caution to the documentation" do
      expect(response.body)
        .to include(%(href="#{ERB::Util.html_escape(documentation_url)}"))
    end
  end
end
