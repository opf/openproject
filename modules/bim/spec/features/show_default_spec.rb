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

require_relative '../support/pages/ifc_models/index'
require_relative '../support/pages/ifc_models/show_default'

describe 'show default model', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:index_page) { Pages::IfcModels::Index.new(project) }
  let(:show_default_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models]) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let(:model) do
    FactoryBot.create(:ifc_model_converted,
                      is_default: model_is_default,
                      project: project,
                      uploader: user)
  end
  let(:model_is_default) { true }

  before do
    login_as(user)
    model
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
      show_default_page.sidebar_shows_viewer_menu true
    end
  end

  context 'without a default model' do
    let(:model_is_default) { false }

    before do
      show_default_page.visit!
    end

    it 'redirects to the index page and displays a notification' do
      expect(index_page)
        .to be_current_page

      index_page.expect_notification(type: :info,
                                     message: I18n.t('ifc_models.no_defaults_warning.title'))
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
