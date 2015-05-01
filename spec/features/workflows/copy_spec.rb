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

require 'spec_helper'

describe 'Workflow copy', type: :feature do
  let(:role) { FactoryGirl.create(:role) }
  let(:type) { FactoryGirl.create(:type) }
  let(:admin)  { FactoryGirl.create(:admin) }
  let(:statuses) { (1..2).map { |_i| FactoryGirl.create(:status) } }
  let(:workflow) {
    FactoryGirl.create(:workflow, role_id: role.id,
                                  type_id: type.id,
                                  old_status_id: statuses[0].id,
                                  new_status_id: statuses[1].id,
                                  author: false,
                                  assignee: false)
  }

  before do
    allow(User).to receive(:current).and_return(admin)
  end

  context 'lala' do
    before do
      workflow.save
      visit url_for(controller: '/workflows', action: :copy)
    end

    it 'shows existing types and roles' do
      select(role.name, from: :source_role_id)
      within('#source_role_id') do
        expect(page).to have_content(role.name)
        expect(page).to have_content("--- #{I18n.t(:actionview_instancetag_blank_option)} ---")
      end
      within('#source_type_id') do
        expect(page).to have_content(type.name)
        expect(page).to have_content("--- #{I18n.t(:actionview_instancetag_blank_option)} ---")
      end
    end
  end
end
