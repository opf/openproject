#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/page_objects/notification'

describe 'Upload attachment to documents',
         js: true,
         with_settings: {
           journal_aggregation_time_minutes: 0,
           notified_events: %w(document_added)
         } do
  let!(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_documents
                                                  manage_documents]
  end
  let!(:other_user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_documents]
  end
  let!(:category) do
    FactoryBot.create(:document_category)
  end
  let(:project) { FactoryBot.create(:project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:image_fixture) { ::UploadedFile.load_from('spec/fixtures/files/image.png') }
  let(:editor) { ::Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  shared_examples 'can upload an image' do
    it 'can upload an image' do
      visit new_project_document_path(project)

      expect(page).to have_selector('#new_document', wait: 10)
      SeleniumHubWaiter.wait
      select(category.name, from: 'Category')
      fill_in "Title", with: 'New documentation'

      # adding an image
      editor.drag_attachment image_fixture.path, 'Image uploaded on creation'
      expect(page).to have_selector('attachment-list-item', text: 'image.png')

      perform_enqueued_jobs do
        click_on 'Create'
      end

      # Expect it to be present on the index page
      expect(page).to have_selector('.document-category-elements--header', text: 'New documentation')
      expect(page).to have_selector('#content img', count: 1)
      expect(page).to have_content('Image uploaded on creation')

      document = ::Document.last
      expect(document.title).to eq 'New documentation'

      # Expect it to be present on the show page
      SeleniumHubWaiter.wait
      find('.document-category-elements--header a', text: 'New documentation').click
      expect(page).to have_current_path "/documents/#{document.id}", wait: 10
      expect(page).to have_selector('#content img', count: 1)
      expect(page).to have_content('Image uploaded on creation')

      # Adding a second image
      # We should be using the 'Edit' button at the top but that leads to flickering specs
      # FIXME: yes indeed
      visit edit_document_path(document)

      # editor.click_and_type_slowly 'abc'
      SeleniumHubWaiter.wait
      editor.drag_attachment image_fixture.path, 'Image uploaded the second time'
      expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)

      perform_enqueued_jobs do
        click_on 'Save'
      end

      # Expect both images to be present on the show page
      expect(page).to have_selector('#content img', count: 2)
      expect(page).to have_content('Image uploaded on creation')
      expect(page).to have_content('Image uploaded the second time')
      expect(page).to have_selector('attachment-list-item', text: 'image.png', count: 2)

      # Expect a mail to be sent to the user having subscribed to all notifications
      expect(ActionMailer::Base.deliveries.size)
        .to be 1

      expect(ActionMailer::Base.deliveries.last.to)
        .to match_array [other_user.mail]

      expect(ActionMailer::Base.deliveries.last.subject)
        .to include 'New documentation'
    end
  end

  context 'with direct uploads (Regression #34285)', with_direct_uploads: true do
    before do
      allow_any_instance_of(Attachment).to receive(:diskfile).and_return image_fixture
    end

    it_behaves_like 'can upload an image'
  end

  context 'internal upload', with_direct_uploads: false do
    it_behaves_like 'can upload an image'
  end
end
