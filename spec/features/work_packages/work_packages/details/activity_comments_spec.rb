#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rails_helper'
require_relative '../support/shared_contexts'
require_relative '../support/shared_examples'

describe 'activity comments', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let!(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:user) { FactoryGirl.create :admin }

  include_context 'maximized window'

  before do
    allow(User).to receive(:current).and_return(user)
    visit project_work_packages_path(project)

    ensure_wp_table_loaded

    row = page.find("#work-package-#{work_package.id}")
    row.double_click

    ng_wait
  end

  it 'should alert user if navigating with unsaved form' do
    fill_in I18n.t('js.label_add_comment_title'), with: 'Foobar'

    visit root_path

    page.driver.browser.switch_to.alert.accept

    expect(current_path).to eq(root_path)
  end

  it 'should not alert if comment has been submitted' do
    fill_in I18n.t('js.label_add_comment_title'), with: 'Foobar'

    click_button I18n.t('js.label_add_comment')

    visit root_path

    expect(current_path).to eq(root_path)
  end
end
