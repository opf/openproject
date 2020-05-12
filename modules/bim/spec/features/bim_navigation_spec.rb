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

require_relative '../spec_helper'

describe 'BIM navigation spec',
         type: :feature,
         with_config: { edition: 'bim' },
         js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages]) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let!(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      project: project,
                      uploader: user)
  end

  let(:card_view) { ::Pages::WorkPackageCards.new(project) }
  let(:details_view) { ::Pages::BcfDetailsPage.new(work_package, project) }
  let(:full_view) { Pages::FullWorkPackage.new(work_package) }
  let(:model_tree) { ::Components::XeokitModelTree.new }

  shared_examples 'can switch from split to viewer to list-only' do
    before do
      login_as(user)
      model_page.visit!
      model_page.finished_loading
    end

    context 'deep link on the page' do
      before do
        login_as(user)
        model_page.visit!
        model_page.finished_loading
      end

      it 'can switch between the different view modes' do
        # Should be at split view
        model_page.model_viewer_visible true
        model_page.model_viewer_shows_a_toolbar true
        model_page.page_shows_a_toolbar true
        model_tree.sidebar_shows_viewer_menu true
        expect(page).to have_selector('.wp-cards-container')
        card_view.expect_work_package_listed work_package

        # Go to single view
        card_view.open_full_screen_by_details(work_package)

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.switch_to_tab tab: 'Activity'
        details_view.expect_tab 'Activity'

        # Going to full screen and back again
        details_view.switch_to_fullscreen
        full_view.expect_tab 'Activity'
        full_view.go_back

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.go_back

        details_view.expect_closed
        card_view.expect_work_package_listed work_package

        # Go to viewer only
        model_page.switch_view 'Viewer'

        model_page.model_viewer_visible true
        expect(page).to have_no_selector('.wp-cards-container')

        # Go to list only
        model_page.switch_view 'Cards'

        model_page.model_viewer_visible false
        expect(page).to have_selector('.wp-cards-container')
        card_view.expect_work_package_listed work_package

        # Go to single view
        card_view.open_full_screen_by_details(work_package)

        details_view.ensure_page_loaded
        details_view.expect_subject
        details_view.switch_to_tab tab: 'Activity'
        details_view.expect_tab 'Activity'
        details_view.close
        details_view.expect_closed
      end
    end
  end

  context 'on default page' do
    let(:model_page) { ::Pages::IfcModels::ShowDefault.new project }
    it_behaves_like 'can switch from split to viewer to list-only'
  end

  context 'on show page' do
    let(:model_page) { ::Pages::IfcModels::Show.new project, model.id }
    it_behaves_like 'can switch from split to viewer to list-only'
  end
end
