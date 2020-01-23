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

require 'spec_helper'

require_relative '../support/pages/ifc_models/show'

describe 'model viewer', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models]) }
  let(:view_role) { FactoryBot.create(:role, permissions: %i[view_ifc_models]) }
  let(:no_permissions_role) { FactoryBot.create(:role, permissions: %i[]) }

  let(:user) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: role }

  let(:view_user) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: view_role }

  let(:user_without_permissions) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: no_permissions_role }

  let(:model) { FactoryBot.create(:ifc_model_converted,
                                  project: project,
                                  uploader: user) }

  let(:show_model_page) { Pages::IfcModels::Show.new(project, model.id) }

  context 'with all permissions' do
    before do
      login_as(user)
    end

    it 'loads and shows the viewer correctly' do
      show_model_page.visit!
      show_model_page.finished_loading

      show_model_page.model_viewer_visible true
      show_model_page.model_viewer_shows_a_toolbar true
      show_model_page.page_shows_a_toolbar true
      show_model_page.sidebar_shows_viewer_menu true
    end
  end

  context 'with only viewing permissions' do
    before do
      login_as(view_user)
    end

    it 'loads and shows the viewer correctly' do
      show_model_page.visit!
      show_model_page.finished_loading

      show_model_page.model_viewer_visible true
      show_model_page.model_viewer_shows_a_toolbar true
      show_model_page.page_shows_a_toolbar false
      show_model_page.sidebar_shows_viewer_menu true
    end
  end

  context 'without any permissions' do
    before do
      login_as(user_without_permissions)
    end

    it 'shows no viewer' do
      show_model_page.visit!

      expected = '[Error 403] You are not authorized to access this page.'
      expect(page).to have_selector('.notification-box.-error', text: expected)

      show_model_page.model_viewer_visible false
      show_model_page.model_viewer_shows_a_toolbar false
      show_model_page.page_shows_a_toolbar false
      show_model_page.sidebar_shows_viewer_menu false
    end
  end
end
