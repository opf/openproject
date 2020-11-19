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

describe 'direct IFC upload', type: :feature, js: true, with_direct_uploads: :redirect, with_config: { edition: 'bim' } do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[bim] }
  let(:ifc_fixture) { ::UploadedFile.load_from('modules/bim/spec/fixtures/files/minimal.ifc') }

  before do
    login_as user

    allow_any_instance_of(Bim::IfcModels::BaseContract).to receive(:ifc_attachment_is_ifc).and_return true
  end

  it 'should work' do
    visit new_bcf_project_ifc_model_path(project_id: project.identifier)

    page.attach_file("file", ifc_fixture.path, visible: :all)

    click_on "Create"

    expect(page).to have_content("Upload succeeded")

    expect(Attachment.count).to eq 1
    expect(Attachment.first[:file]).to eq 'model.ifc'

    expect(Bim::IfcModels::IfcModel.count).to eq 1
    expect(Bim::IfcModels::IfcModel.first.title).to eq "minimal.ifc"
  end
end
