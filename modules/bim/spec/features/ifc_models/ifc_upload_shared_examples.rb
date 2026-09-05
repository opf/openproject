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

RSpec.shared_examples "can upload an IFC file" do
  let(:user) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %i[bim]) }
  let(:ifc_fixture) { UploadedFile.load_from("modules/bim/spec/fixtures/files/minimal.ifc") }
  let(:set_tick_is_default_after_file) { true }

  before do
    login_as user

    allow_any_instance_of(Bim::IfcModels::BaseContract).to receive(:ifc_attachment_is_ifc).and_return true
  end

  shared_examples "allows uploading an IFC file" do
    it "allows uploading an IFC file" do
      visit new_bcf_project_ifc_model_path(project_id: project.identifier)

      page.check "Default model" unless set_tick_is_default_after_file
      page.attach_file("file", ifc_fixture.path, visible: :all)
      page.check "Default model" if set_tick_is_default_after_file

      click_on "Create"

      expect(page).to have_text("Upload succeeded")

      expect(Attachment.count).to eq 1
      expect(Attachment.first[:file]).to eq model_name

      expect(Bim::IfcModels::IfcModel.count).to eq 1

      expect(Bim::IfcModels::IfcModel.first.is_default).to be_truthy
    end
  end

  context "when setting checkbox is_default before selecting file" do
    let(:set_tick_is_default_after_file) { false }

    it_behaves_like "allows uploading an IFC file"
  end

  context "when setting checkbox is_default after selecting file" do
    it_behaves_like "allows uploading an IFC file"
  end
end
