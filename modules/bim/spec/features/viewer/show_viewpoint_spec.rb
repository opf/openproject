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

describe 'Show viewpoint in model viewer',
         with_config: { edition: 'bim' },
         type: :feature,
         js: true do
  let(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: [:bim, :work_package_tracking],
                      parent: parent_project)
  end
  let(:parent_project) { nil }
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
  let(:show_model_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:card_view) { ::Pages::WorkPackageCards.new(project) }
  let(:bcf_details) { ::Pages::BcfDetailsPage.new(work_package, project) }

  shared_examples 'has the minimal viewpoint shown' do
    it 'loads the minimal viewpoint in the viewer' do
      model_tree.select_sidebar_tab 'Objects'
      model_tree.expand_tree
      model_tree.expect_checked 'minimal'
      model_tree.all_checkboxes.each do |label, checkbox|
        if label.text == 'minimal' || label.text == 'LUB_Segment_new:S_WHG_Ess:7243035'
          expect(checkbox.checked?).to eq(true)
        else
          expect(checkbox.checked?).to eq(false)
        end
      end
    end
  end

  before do
    login_as(user)
    show_model_page.visit!
    show_model_page.finished_loading
    card_view.expect_work_package_listed work_package
  end

  context 'clicking on the card' do
    before do
      card_view.select_work_package work_package
      card_view.expect_work_package_selected work_package, true
    end

    it_behaves_like 'has the minimal viewpoint shown'
  end

  context 'when in details view' do
    before do
      card_view.open_full_screen_by_details work_package
      bcf_details.expect_viewpoint_count 1
      bcf_details.show_current_viewpoint
    end

    it_behaves_like 'has the minimal viewpoint shown'
  end

  context 'when in work packages details view' do
    let(:wp_details) { ::Pages::SplitWorkPackage.new(work_package, project) }
    
    shared_examples "moves to the BCF page" do
      it 'moves to the bcf page' do
        wp_details.visit!
        bcf_details.expect_viewpoint_count 1
        bcf_details.show_current_viewpoint

        path = Regexp.escape("bcf/split/details/#{work_package.id}/overview")
        expect(page).to have_current_path /#{path}/

        expect(page).to have_current_path /#{project.id}/
      end
    end

    context "current project is the work package's project" do
      it_behaves_like 'moves to the BCF page'
    end

    context "current project is a parent of the work package's project" do
      let(:parent_project) { FactoryBot.create :project, enabled_module_names: [:work_package_tracking] }
      let(:wp_details) { ::Pages::SplitWorkPackage.new(work_package, parent_project) }

      it_behaves_like "moves to the BCF page"
    end

    context 'when user does not have view_linked_issues permission' do
      let(:permissions) { %i[view_ifc_models view_work_packages] }

      let(:user) do
        FactoryBot.create :user,
                          member_in_project: project,
                          member_with_permissions: permissions
      end

      it 'does not show the viewpoint' do
        wp_details.visit!
        bcf_details.expect_viewpoint_count 0
        expect(page).to have_no_selector('h3.attributes-group--header-text', text: 'BCF')
      end
    end
  end
end
