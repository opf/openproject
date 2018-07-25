#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'
require 'features/page_objects/notification'

describe 'Upload attachment to overview page', js: true do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[edit_project]
  end
  let(:project) { FactoryBot.create(:project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { ::Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  it 'can upload an image to the page' do
    visit my_projects_overview_path(project)

    within '.toolbar-items' do
      select('Add teaser ...', from: 'block-select')
    end

    fill_in "Title", with: 'New teaser'

    # adding an image
    editor.in_editor do |container, editable|
      attachments.drag_and_drop_file(editable, image_fixture)

      # Besides testing caption functionality this also slows down clicking on the submit button
      # so that the image is properly embedded
      editable.find('figure.image figcaption').base.send_keys('Image uploaded on creation')
    end

    within '.textile-form' do
      click_on 'Save'
    end

    expect(page).to have_selector('#content img', count: 1)
    expect(page).to have_content('Image uploaded on creation')
    expect(page).to have_selector('.attachments', text: 'image.png')

    find('.block-teaser .icon-edit').click

    editor.in_editor do |container, editable|
      attachments.drag_and_drop_file(editable, image_fixture)

      # Besides testing caption functionality this also slows down clicking on the submit button
      # so that the image is properly embedded
      editable.find('figure.image figcaption').base.send_keys('Image uploaded the second time')
    end

    within '.textile-form' do
      click_on 'Save'
    end

    expect(page).to have_selector('#content img', count: 2)
    expect(page).to have_selector('.attachments a', text: 'image.png', count: 2)
    expect(page).to have_content('Image uploaded on creation')
    expect(page).to have_content('Image uploaded the second time')
  end
end