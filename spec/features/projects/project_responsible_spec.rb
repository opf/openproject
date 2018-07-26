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
require 'features/projects/project_settings_page'

describe 'Projects responsible setting',
         type: :feature,
         with_settings: { user_format: :firstname_lastname },
         js: true do
  include Capybara::Select2
  let!(:admin) { FactoryBot.create :admin }
  let!(:user) { FactoryBot.create(:user, firstname: 'Foo', lastname: 'Bar', member_in_project: project) }

  let!(:project) do
    FactoryBot.create(:project,
                      name: 'Plain project',
                      identifier: 'plain-project')
  end
  let(:settings_page) { ProjectSettingsPage.new(project) }

  before do
    login_as admin
  end

  it 'can set the responsible (Regression test #28091)' do
    settings_page.visit_settings
    expect(page).to have_selector('.form--label', text: 'Responsible')

    select2('Foo Bar', css: '#s2id_project_responsible_id')
    click_on 'Save'

    expect(page).to have_selector('.select2-chosen', text: 'Foo Bar')
    project.reload
    expect(project.responsible).to eq(user)
  end
end
