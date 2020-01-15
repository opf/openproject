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

require_relative '../support/pages/overview'

describe 'Overview page on the fly creation if user lacks :mange_overview permission',
         type: :feature, js: true, with_mail: false do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }

  let(:permissions) do
    %i[view_work_packages]
  end

  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:overview_page) do
    Pages::Overview.new(project)
  end

  before do
    login_as user

    overview_page.visit!
  end

  it 'renders the default view, allows altering and saving' do
    description_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')
    details_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')
    overview_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(3)')

    description_area.expect_to_exist
    details_area.expect_to_exist
    overview_area.expect_to_exist
  end
end
