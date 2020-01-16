#-- encoding: UTF-8

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
require 'features/page_objects/notification'

describe 'Upload attachment to budget', js: true do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_cost_objects
                                                  edit_cost_objects]
  end
  let(:project) { FactoryBot.create(:project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { ::Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  it 'can upload an image to new and existing budgets via drag & drop' do
    visit projects_cost_objects_path(project)

    within '.toolbar-items' do
      click_on "Budget"
    end

    fill_in "Subject", with: 'New budget'

    # adding an image
    editor.drag_attachment image_fixture, 'Image uploaded on creation'

    expect(page).to have_selector('attachment-list-item', text: 'image.png')

    click_on 'Create'

    expect(page).to have_selector('#content img', count: 1)
    expect(page).to have_content('Image uploaded on creation')
    expect(page).to have_selector('attachment-list-item', text: 'image.png')

    within '.toolbar-items' do
      click_on "Update"
    end

    editor.drag_attachment image_fixture, 'Image uploaded the second time'

    expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)

    click_on 'Submit'

    expect(page).to have_selector('#content img', count: 2)
    expect(page).to have_content('Image uploaded on creation')
    expect(page).to have_content('Image uploaded the second time')
    expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)
  end
end
