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

require_relative '../../spec_helper'

describe 'Delete viewpoint in model viewer',
         with_config: { edition: 'bim' },
         type: :feature,
         js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  let(:user) { FactoryBot.create :admin }

  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let!(:bcf) { FactoryBot.create :bcf_issue, work_package: work_package }
  let!(:viewpoint) { FactoryBot.create :bcf_viewpoint, issue: bcf, viewpoint_name: 'minimal_hidden_except_one' }

  let!(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      title: 'minimal',
                      project: project,
                      uploader: user)
  end

  let(:model_tree) { ::Components::XeokitModelTree.new }
  let(:bcf_details) { ::Pages::BcfDetailsPage.new(work_package, project) }

  before do
    login_as(user)
    bcf_details.visit!
  end

  it 'can delete the viewpoint through the gallery' do
    bcf_details.ensure_page_loaded
    bcf_details.expect_viewpoint_count 1
    bcf_details.show_current_viewpoint

    # Delete but don't confirm alert
    bcf_details.delete_current_viewpoint confirm: false

    sleep 1
    bcf_details.expect_viewpoint_count 1

    # Delete for real now
    bcf_details.delete_current_viewpoint confirm: true
    sleep 1
    bcf_details.expect_viewpoint_count 0

    bcf.reload
    expect(bcf.viewpoints).to be_empty
  end
end
