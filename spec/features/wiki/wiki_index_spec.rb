#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
require 'features/page_objects/notification'
require 'features/work_packages/shared_contexts'
require 'features/work_packages/work_packages_page'

feature 'Wiki menu items' do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %w[view_wiki_pages]
  end
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[wiki] }
  let(:wiki) { project.wiki }

  before do
    login_as user
    visit index_project_wiki_index_path(project)
  end

  it 'allows managing the menu item of a wiki page' do
    expect(page).to have_selector('h2', text: 'Table of Contents')
    expect(page).to have_no_selector('.main-menu--children .selected')
  end
end
