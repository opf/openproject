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

describe 'BIM Revit Add-in navigation spec',
         type: :feature,
         with_config: { edition: 'bim' },
         js: true,
         driver: :chrome_headless_revit_addin do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages]) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let(:model_page) { ::Pages::IfcModels::ShowDefault.new(project) }

  before do
    login_as(user)
    model_page.visit!
    model_page.finished_loading
  end

  it 'shows "Cards" view by default' do
    model_page.expect_view_toggle_at 'Cards'
  end
end
