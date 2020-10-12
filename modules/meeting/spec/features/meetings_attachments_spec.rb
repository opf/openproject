require 'spec_helper'
require 'features/page_objects/notification'

describe 'Add an attachment to a meeting (agenda)', js: true do
  let(:role) do
    FactoryBot.create :role, permissions: %i[view_meetings edit_meetings create_meeting_agendas]
  end

  let(:dev) do
    FactoryBot.create :user, member_in_project: project, member_through_role: role
  end

  let(:project) { FactoryBot.create(:project) }

  let(:meeting) do
    FactoryBot.create(
      :meeting,
      project: project,
      title: "Versammlung",
      agenda: FactoryBot.create(:meeting_agenda, text: "Versammlung")
    )
  end

  let(:attachments) { ::Components::Attachments.new }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(dev)

    visit "/meetings/#{meeting.id}"

    within "#tab-content-agenda .toolbar" do
      click_link "Edit"
    end
  end

  describe 'wysiwyg editor' do
    context 'on an existing page' do
      it 'can upload an image via drag & drop' do
        target = find('.ck-content')

        editor.expect_button 'Insert image'

        editor.drag_attachment image_fixture, 'Some image caption'

        click_on "Save"

        content = find("div.meeting_content.meeting_agenda")

        expect(content).to have_selector('img')
        expect(content).to have_content('Some image caption')
      end
    end
  end

  describe 'attachment dropzone' do
    it 'can upload an image via attaching and drag & drop' do
      # called the same for all Wysiwyg dditors no matter if for work packages
      # or not
      container = page.find('.wp-attachment-upload')
      scroll_to_element(container)

      ##
      # Attach file manually
      expect(page).to have_no_selector('.work-package--attachments--filename')
      attachments.attach_file_on_input(image_fixture)
      expect(page).not_to have_selector('notification-upload-progress')
      expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png', wait: 5)

      ##
      # and via drag & drop
      attachments.drag_and_drop_file(container, Rails.root.join('spec/fixtures/files/image.png'))
      expect(page).not_to have_selector('notification-upload-progress')
      expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png', count: 2, wait: 5)
    end
  end
end
