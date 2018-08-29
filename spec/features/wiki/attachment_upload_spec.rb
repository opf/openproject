#-- encoding: UTF-8

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

describe 'Upload attachment to wiki page', js: true do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_wiki_pages edit_wiki_pages]
  end
  let(:project) { FactoryBot.create(:project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { ::Components::WysiwygEditor.new }
  let(:wiki_page_content) { project.wiki.pages.first.content.text }

  before do
    login_as(user)
  end

  it 'can upload an image to new and existing wiki page via drag & drop' do
    visit project_wiki_path(project, 'test')

    # adding an image
    editor.in_editor do |container, editable|
      attachments.drag_and_drop_file(editable, image_fixture)

      # Besides testing caption functionality this also slows down clicking on the submit button
      # so that the image is properly embedded
      editable.find('figure.image figcaption').base.send_keys('Image uploaded the first time')
    end

    expect(page).to have_selector('attachment-list-item', text: 'image.png')

    click_on 'Save'

    expect(page).to have_selector('#content img', count: 1)
    expect(page).to have_content('Image uploaded the first time')
    expect(page).to have_selector('attachment-list-item', text: 'image.png')

    within '.toolbar-items' do
      click_on "Edit"
    end

    # Replace one image with a named attachment URL (Regression #28381)
    editor.set_markdown "![my-first-image](image.png)"

    editor.in_editor do |container, editable|
      # Expect URL is mapped to the correct URL
      expect(container).to have_selector('img[src^="/api/v3/attachments/"')
      expect(container).to have_no_selector('img[src="image.png"]')

      attachments.drag_and_drop_file(editable, image_fixture)

      # Besides testing caption functionality this also slows down clicking on the submit button
      # so that the image is properly embedded
      editable.find('figure.image figcaption').base.send_keys('Image uploaded the second time')
    end

    expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)

    click_on 'Save'

    expect(page).to have_selector('#content img', count: 2)
    expect(page).to have_content('Image uploaded the second time')
    expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)

    # Rendered once through the name in the backend
    expect(page).to have_selector('img[src^="/attachments', count: 1)

    # And once with the full url
    expect(page).to have_selector('img[src^="/api/v3/attachments/"', count: 1)

    expect(wiki_page_content).to include '![my-first-image](image.png)'
    expect(wiki_page_content).to include '![](/api/v3/attachments'
  end

  it 'can upload an image on the new wiki page and recover from an error without losing the attachment (Regression #28171)' do
    visit project_wiki_path(project, 'test')

    expect(page).to have_selector('#content_page_title')
    expect(page).to have_selector('.work-package--attachments--drop-box')

    # Upload image to dropzone
    expect(page).to have_no_selector('.work-package--attachments--filename')
    attachments.attach_file_on_input(image_fixture)
    expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png')

    # Assume we could still save the page with an empty title
    page.execute_script 'jQuery("#content_page_title").removeAttr("required aria-required");'
    # Remove title so we will result in an error
    fill_in 'content_page_title', with: ''
    click_on 'Save'

    expect(page).to have_selector('#errorExplanation', text: "Title can't be blank.")
    expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png')

    editor.in_editor do |container, editable|
      editable.send_keys 'hello there.'
    end

    fill_in 'content_page_title', with: 'Test'
    click_on 'Save'

    expect(page).to have_selector('.controller-wiki.action-show')
    expect(page).to have_selector('h2', text: 'Test')
    expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png')
  end
end
