#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require 'spec_helper'

feature 'Query menu items' do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }

  before do
    User.stub(:current).and_return user
  end

  context 'with identical names' do
    let(:query_a) { FactoryGirl.create :public_query, name: 'some query.', project: project }
    let(:query_b) { FactoryGirl.create :public_query, name: query_a.name, project: project }

    let!(:menu_item_a) { FactoryGirl.create :query_menu_item, query: query_a }
    let!(:menu_item_b) { FactoryGirl.create :query_menu_item, query: query_b }

    it 'can be shown' do
      visit "/projects/#{project.identifier}"

      expect(page).to have_selector('a', text: query_a.name, count: 2)
    end
  end

  context 'with dots in their name' do
    let(:query) { FactoryGirl.create :public_query, name: 'OP 3.0', project: project }

    def check(input_name)
      find(:css, "input[name=#{input_name}]").set true
    end

    it 'can be added', js: true do
      pending('does not work on Travis for some reason cause the settings button is invisible...') do
        visit project_work_packages_path(project, query_id: query.id)

        click_on 'Settings'
        click_on 'Share ...'
        check 'show_in_menu'
        click_on 'Save'

        expect(page).to have_text('Successful update')
        expect(page).to have_selector('a', text: query.name)
      end
    end
  end
end
