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

describe 'work package hierarchies for milestones', js: true, selenium: true do
  let(:user) { FactoryBot.create :admin }
  let(:type) { FactoryBot.create(:type, is_milestone: true) }
  let(:project) { FactoryBot.create(:project, types: [type]) }
  let(:work_package) { FactoryBot.create(:work_package, project: project, type: type) }
  let(:relations) { ::Components::WorkPackages::Relations.new(work_package) }
  let(:tabs) { ::Components::WorkPackages::Tabs.new(work_package) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:relations_tab) { find('.tabrow li.selected', text: 'RELATIONS') }
  let(:visit) { true }

  before do
    login_as user
    wp_page.visit_tab!('relations')
    expect_angular_frontend_initialized
    wp_page.expect_subject
    loading_indicator_saveguard
  end

  it 'does not provide links to add children or existing children (Regression #28745)' do
    within('.wp-relations--children') do
      expect(page).to have_no_text('Add existing child')
      expect(page).to have_no_text('Create new child')
      expect(page).to have_no_selector('wp-inline-create--add-link')
    end
  end
end
