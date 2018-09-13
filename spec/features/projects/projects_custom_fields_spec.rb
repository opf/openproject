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

describe 'Projects custom fields', type: :feature do
  let(:current_user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project, name: 'Foo project', identifier: 'foo-project') }
  let!(:custom_field) do
    FactoryBot.create(:bool_project_custom_field)
  end

  let(:identifier) { "project_custom_field_values_#{custom_field.id}" }

  before do
    login_as current_user
  end

  scenario 'allows settings the project boolean CF (regression #26313)', js: true do
    visit settings_project_path(id: project.id)
    expect(page).to have_no_checked_field identifier
    check identifier

    click_on 'Save'
    expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))
    expect(page).to have_checked_field identifier
  end
end
