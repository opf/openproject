require 'spec_helper'
require 'features/page_objects/notification'

describe 'Upload attachment to work package', js: true do
  let(:role) do
    FactoryBot.create :role,
                      permissions: %i[view_work_packages add_work_packages edit_work_packages]
  end
  let(:dev) do
    FactoryBot.create :user,
                      firstname: 'Dev',
                      lastname: 'Guy',
                      member_in_project: project,
                      member_through_role: role
  end
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project, description: 'Initial description') }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:field) { TextEditorField.new wp_page, 'description' }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(dev)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  describe 'wysiwyg editor' do
    context 'on an existing page' do
      before do
        wp_page.visit!
        wp_page.ensure_page_loaded
      end

      it 'can upload an image via drag & drop' do
        # Activate the edit field
        field.activate!

        editor.expect_button 'Insert image'

        editor.drag_attachment image_fixture, 'Some image caption'

        field.submit_by_click

        expect(field.display_element).to have_selector('img')
        expect(field.display_element).to have_content('Some image caption')
      end

      context 'with a user that is not allowed to add images (Regression #28541)' do
        let(:role) do
          FactoryBot.create :role,
                            permissions: %i[view_work_packages add_work_packages add_work_package_notes]
        end
        let(:selector) { '.work-packages--activity--add-comment' }
        let(:comment_field) do
          TextEditorField.new wp_page,
                              'comment',
                              selector: selector
        end
        let(:editor) { Components::WysiwygEditor.new '.work-packages--activity--add-comment' }

        it 'can open the editor to add an image, but image upload is not shown' do
          # Add comment
          comment_field.activate!

          # Button should be hidden
          editor.expect_no_button 'Insert image'

          editor.click_and_type_slowly 'this is a comment!1'
          comment_field.submit_by_click

          wp_page.expect_comment text: 'this is a comment!1'
        end
      end
    end

    context 'on a new page' do
      let!(:new_page) { Pages::FullWorkPackageCreate.new }
      let!(:type) { FactoryBot.create(:type_task) }
      let!(:status) { FactoryBot.create(:status, is_default: true) }
      let!(:priority) { FactoryBot.create(:priority, is_default: true) }
      let!(:project) do
        FactoryBot.create(:project, types: [type])
      end

      before do
        visit new_project_work_packages_path(project.identifier, type: type.id)
      end

      it 'can upload an image via drag & drop (Regression #28189)' do
        subject = new_page.edit_field :subject
        subject.set_value 'My subject'

        target = find('.ck-content')
        attachments.drag_and_drop_file(target, image_fixture)

        sleep 2
        expect(page).not_to have_selector('notification-upload-progress')

        editor.in_editor do |container, editable|
          expect(editable).to have_selector('img[src*="/api/v3/attachments/"]', wait: 20)
        end

        sleep 2

        # Besides testing caption functionality this also slows down clicking on the submit button
        # so that the image is properly embedded
        caption = page.find('figure.image figcaption')
        caption.click(x: 10, y: 10)
        sleep 0.2
        caption.base.send_keys('Some image caption')

        sleep 2

        scroll_to_and_click find('#work-packages--edit-actions-save')

        wp_page.expect_notification(
          message: 'Successful creation.'
        )

        field = wp_page.edit_field :description

        expect(field.display_element).to have_selector('img')
        expect(field.display_element).to have_content('Some image caption')

        wp = WorkPackage.last
        expect(wp.subject).to eq('My subject')
        expect(wp.attachments.count).to eq(1)
      end
    end
  end

  describe 'attachment dropzone' do
    it 'can upload an image via attaching and drag & drop' do
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
