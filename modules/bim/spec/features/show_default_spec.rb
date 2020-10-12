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

describe 'show default model',
         with_config: { edition: 'bim' },
         type: :feature,
         js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[bim work_package_tracking] }
  let(:index_page) { Pages::IfcModels::Index.new(project) }
  let(:show_default_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models view_work_packages manage_ifc_models]) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      is_default: model_is_default,
                      project: project,
                      uploader: user)
  end
  let(:model_is_default) { true }
  let(:model_tree) { ::Components::XeokitModelTree.new }

  before do
    login_as(user)
    model
  end

  context 'when the work package module not loaded' do
    let(:project) { FactoryBot.create :project, enabled_module_names: [:bim] }

    it 'shows an error loading the page' do
      show_default_page.visit!
      show_default_page.expect_notification(type: :error, message: 'Your view is erroneous and could not be processed')
    end
  end

  context 'with everything ready' do
    before do
      show_default_page.visit!
      show_default_page.finished_loading
    end

    it 'loads and shows the viewer correctly' do
      show_default_page.model_viewer_visible true
      show_default_page.model_viewer_shows_a_toolbar true
      show_default_page.page_shows_a_toolbar true
      model_tree.sidebar_shows_viewer_menu true
    end
  end

  context 'with the default model not being processed' do
    before do
      model.xkt_attachment.destroy

      show_default_page.visit!
    end

    it 'renders a notification' do
      show_default_page
        .expect_notification(type: :info,
                             message: I18n.t(:'ifc_models.processing_notice.processing_default'))
    end
  end
end
