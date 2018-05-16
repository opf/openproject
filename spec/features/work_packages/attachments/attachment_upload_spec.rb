require 'spec_helper'
require 'features/page_objects/notification'

describe 'Upload attachment to work package', js: true do
  let(:dev_role) do
    FactoryBot.create :role,
                      permissions: %i[view_work_packages add_work_packages edit_work_packages]
  end
  let(:dev) do
    FactoryBot.create :user,
                      firstname: 'Dev',
                      lastname: 'Guy',
                      member_in_project: project,
                      member_through_role: dev_role
  end
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project, description: 'Initial description') }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }
  let(:attachments_dropper) { ::Components::AttachmentsDropper.new }
  let(:field) { WorkPackageEditorField.new wp_page, 'description' }

  before do
    login_as(dev)
    wp_page.visit!
  end

  describe 'wysiwyg editor', with_settings: { text_formatting: 'markdown', use_wysiwyg?: 1 } do
    it 'can upload an image via drag & drop' do

      # Activate the edit field
      field.activate!
      target = find('.op-ckeditor-element')
      attachments_dropper.drag_and_drop_file(target, Rails.root.join('spec/fixtures/files/image.png'))

      field.submit_by_click
      expect(field.display_element).to have_selector('img')
    end
  end
end
