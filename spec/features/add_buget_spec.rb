#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'adding a new budget', type: :feature, js: true do
  let(:project) { FactoryGirl.create :project_with_types }
  let(:user) { FactoryGirl.create :admin }

  before do
    allow(User).to receive(:current).and_return user
  end

  it 'shows link to create a new budget' do
    visit projects_cost_objects_path(project)

    click_on("Add budget")

    expect(page).to have_content "New budget"
    expect(page).to have_content "Description"
    expect(page).to have_content "Subject"
  end

  it 'create the budget' do
    visit new_projects_cost_object_path(project)

    fill_in("Subject", with: 'My subject')

    click_on "Create"

    expect(page).to have_content "Successful creation"
    expect(page).to have_content "My subject"
  end
end
