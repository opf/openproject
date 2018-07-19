require 'spec_helper'
require 'features/page_objects/notification'

describe 'Upload attachment to work package', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project) }
  let(:attachments) { ::Components::Attachments.new }
  let(:field) { WorkPackageEditorField.new wp_page, 'description' }
  let(:image_fixture) { Rails.root.join('spec/fixtures/files/image.png') }
  let(:editor) { ::Components::WysiwygEditor.new }

  describe 'on wiki pages' do
    let(:wiki_page) {
      FactoryBot.create :wiki_page,
                        title: 'Test',
                        content: FactoryBot.build(:wiki_content, text: '# My page')
    }

    before do
      login_as(user)

      project.wiki.pages << wiki_page
      project.wiki.save!
      visit edit_project_wiki_path(project, :test)
    end

    it 'can upload an image via drag & drop' do
      editor.in_editor do |container, editable|
        attachments.drag_and_drop_file(editable, image_fixture)

        # Besides testing caption functionality this also slows down clicking on the submit button
        # so that the image is properly embedded
        editable.find('figure.image figcaption').base.send_keys('Some image caption')
      end

      click_on 'Save'

      expect(page).to have_selector('#content img')
      expect(page).to have_content('Some image caption')
    end
  end
end
