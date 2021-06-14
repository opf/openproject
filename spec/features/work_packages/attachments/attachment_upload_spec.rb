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
  let(:image_fixture) { UploadedFile.load_from('spec/fixtures/files/image.png') }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(dev)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  describe 'wysiwyg editor' do
    context 'for an existing work package' do
      before do
        wp_page.visit!
        wp_page.ensure_page_loaded
      end

      it 'can upload an image via drag & drop' do
        # Activate the edit field
        field.activate!

        editor.expect_button 'Insert image'

        editor.drag_attachment image_fixture.path, 'Some image caption'

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

    context 'for a new work package' do
      shared_examples 'it supports image uploads via drag & drop' do
        let!(:new_page) { Pages::FullWorkPackageCreate.new }
        let!(:type) { FactoryBot.create(:type_task) }
        let!(:status) { FactoryBot.create(:status, is_default: true) }
        let!(:workflow) { FactoryBot.create(:workflow, type: type, old_status: status, role: role) }
        let!(:priority) { FactoryBot.create(:priority, is_default: true) }
        let!(:project) do
          FactoryBot.create(:project, types: [type])
        end

        let(:post_conditions) { nil }

        before do
          visit new_project_work_packages_path(project.identifier, type: type.id)
        end

        it 'can upload an image via drag & drop (Regression #28189)' do
          subject = new_page.edit_field :subject
          subject.set_value 'My subject'

          target = find('.ck-content')
          attachments.drag_and_drop_file(target, image_fixture.path)

          sleep 2
          expect(page).not_to have_selector('notification-upload-progress')

          editor.in_editor do |_container, editable|
            expect(editable).to have_selector('img[src*="/api/v3/attachments/"]', wait: 20)
            expect(editable).not_to have_selector('.ck-upload-placeholder-loader')
          end

          sleep 2

          # Besides testing caption functionality this also slows down clicking on the submit button
          # so that the image is properly embedded
          caption = page.find('.op-uc-figure .op-uc-figure--description')
          caption.click(x: 10, y: 10)
          sleep 0.2
          caption.base.send_keys('Some image caption')

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

          post_conditions
        end
      end

      it_behaves_like 'it supports image uploads via drag & drop'

      # We do a complete integration test for direct uploads on this example.
      # If this works all parts in the backend and frontend work properly together.
      # Technically one could test this not only for new work packages, but also for existing
      # ones, and for new and existing other attachable resources. But the code is the same
      # everywhere so if this works it should work everywhere else too.
      context 'with direct uploads', with_direct_uploads: true do
        before do
          allow_any_instance_of(Attachment).to receive(:diskfile).and_return Struct.new(:path).new(image_fixture.path.to_s)
        end

        it_behaves_like 'it supports image uploads via drag & drop' do
          let(:post_conditions) do
            # check the attachment was created successfully
            expect(Attachment.count).to eq 1
            a = Attachment.first
            expect(a[:file]).to eq image_fixture.basename.to_s

            # check /api/v3/attachments/:id/uploaded was called
            expect(::Attachments::FinishDirectUploadJob).to have_been_enqueued
          end
        end
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
      attachments.attach_file_on_input(image_fixture.path)
      expect(page).not_to have_selector('notification-upload-progress')
      expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png', wait: 5)

      ##
      # and via drag & drop
      attachments.drag_and_drop_file(container, image_fixture.path)
      expect(page).not_to have_selector('notification-upload-progress')
      expect(page).to have_selector('.work-package--attachments--filename', text: 'image.png', count: 2, wait: 5)
    end
  end
end
