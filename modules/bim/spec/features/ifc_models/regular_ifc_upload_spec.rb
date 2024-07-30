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
require_relative "ifc_upload_shared_examples"

RSpec.describe "IFC upload", :js, with_config: { edition: "bim" } do
  it_behaves_like "can upload an IFC file" do
    let(:model_name) { "minimal.ifc" }

    context "when the file size exceeds the allowed maximum", with_settings: { attachment_max_size: 1 } do
      it "renders an error message" do
        visit new_bcf_project_ifc_model_path(project_id: project.identifier)

        page.attach_file("file", ifc_fixture.path, visible: :all)

        click_on "Create"

        expect(page).to have_content("IFC file is too large (maximum size is 1024 Bytes).")
      end
    end
  end
end
