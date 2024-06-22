require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "Add an attachment to a meeting (agenda)", :js, with_cuprite: false do
  let(:role) do
    create(:project_role, permissions: %i[view_meetings edit_meetings create_meeting_agendas])
  end

  let(:dev) do
    create(:user, member_with_roles: { project => role })
  end

  let(:project) { create(:project) }

  let(:meeting) do
    create(
      :meeting,
      project:,
      title: "Versammlung",
      agenda: create(:meeting_agenda, text: "Versammlung")
    )
  end

  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }

  before do
    login_as(dev)

    visit "/meetings/#{meeting.id}"

    within "#tab-content-agenda .toolbar" do
      click_on "Edit"
    end
  end

  describe "wysiwyg editor" do
    context "if on an existing page" do
      it "can upload an image via drag & drop" do
        find(".ck-content")

        editor.expect_button "Upload image from computer"

        editor.drag_attachment image_fixture.path, "Some image caption"

        click_on "Save"

        content = find_test_selector("op-meeting--meeting_agenda")

        expect(content).to have_css("img")
        expect(content).to have_content("Some image caption")
      end
    end
  end

  describe "attachment dropzone" do
    it "can upload an image via attaching and drag & drop" do
      editor.wait_until_loaded
      attachments_list.wait_until_visible

      ##
      # Attach file manually
      editor.attachments_list.expect_empty
      attachments.attach_file_on_input(image_fixture.path)
      editor.wait_until_upload_progress_toaster_cleared
      editor.attachments_list.expect_attached("image.png")

      ##
      # and via drag & drop
      editor.attachments_list.drag_enter
      editor.attachments_list.drop(image_fixture)
      editor.wait_until_upload_progress_toaster_cleared
      editor.attachments_list.expect_attached("image.png", count: 2)
    end
  end
end
