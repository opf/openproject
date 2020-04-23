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

describe 'model viewer',
         with_config: { edition: 'bim' },
         type: :feature,
         js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  # TODO: Add empty viewpoint and stub method to load viewpoints once defined
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages]) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      project: project,
                      uploader: user)
  end

  let(:show_model_page) { Pages::IfcModels::Show.new(project, model.id) }
  let(:model_tree) { ::Components::XeokitModelTree.new }
  let(:card_view) { ::Pages::WorkPackageCards.new(project) }

  context 'with all permissions' do
    describe 'showing a model' do
      before do
        login_as(user)
        work_package
        show_model_page.visit!
        show_model_page.finished_loading
      end

      it 'loads and shows the viewer correctly' do
        show_model_page.model_viewer_visible true
        show_model_page.model_viewer_shows_a_toolbar true
        show_model_page.page_shows_a_toolbar true
        model_tree.sidebar_shows_viewer_menu true
      end

      it 'shows a work package list as cards next to the viewer' do
        show_model_page.model_viewer_visible true
        card_view.expect_work_package_listed work_package
      end
    end

    context 'in a project with no model' do
      it 'shows a warning that no IFC models exist yet' do
        login_as user
        visit defaults_bcf_project_ifc_models_path(project)
        expect(page).to have_selector('.notification-box.-info', text: I18n.t('js.ifc_models.empty_warning'))
      end
    end
  end

  context 'with only viewing permissions' do
    let(:view_role) { FactoryBot.create(:role, permissions: %i[view_ifc_models]) }
    let(:view_user) do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_through_role: view_role
    end

    before do
      login_as(view_user)
      show_model_page.visit!
      show_model_page.finished_loading
    end

    it 'loads and shows the viewer correctly, but has no possibility to edit the model' do
      show_model_page.model_viewer_visible true
      show_model_page.model_viewer_shows_a_toolbar true
      show_model_page.page_shows_a_toolbar false
      model_tree.sidebar_shows_viewer_menu true
    end
  end

  context 'without any permissions' do
    let(:no_permissions_role) { FactoryBot.create(:role, permissions: %i[]) }
    let(:user_without_permissions) do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_through_role: no_permissions_role
    end

    before do
      login_as(user_without_permissions)
      work_package
      show_model_page.visit!
    end

    it 'shows no viewer' do
      expected = '[Error 403] You are not authorized to access this page.'
      expect(page).to have_selector('.notification-box.-error', text: expected)

      show_model_page.model_viewer_visible false
      show_model_page.model_viewer_shows_a_toolbar false
      show_model_page.page_shows_a_toolbar false
      model_tree.sidebar_shows_viewer_menu false
    end

    it 'shows no work package list next to the viewer' do
      show_model_page.model_viewer_visible false
      card_view.expect_work_package_not_listed work_package
    end
  end
end
