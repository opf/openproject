require 'fastimage'

shared_examples 'avatar management' do
  let(:image_base_path) { File.expand_path(File.dirname(__FILE__) + '/../fixtures/') }

  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { false }
  let(:plugin_settings) do
    {
      'enable_gravatars' => enable_gravatars,
      'enable_local_avatars' => enable_local_avatars
    }
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return(plugin_settings)
  end

  describe 'only gravatars enabled' do
    let(:enable_gravatars) { true }

    it 'shows the gravatar avatar' do
      visit avatar_management_path

      expect(page).to have_selector('.form--fieldset-legend', text: 'GRAVATAR')
      expect(page).to have_selector('.avatars--current-gravatar')

      # Local not rendered
      expect(page).to have_no_selector('.form--fieldset-legend', text: 'CUSTOM AVATAR')
      expect(page).to have_no_selector('.avatars--current-local-avatar', text: 'none')
    end
  end

  describe 'only local avatars enabled' do
    let(:enable_local_avatars) { true }

    it 'can upload a new image' do
      visit avatar_management_path
      expect(page).to have_selector('.form--fieldset-legend', text: 'CUSTOM AVATAR')
      expect(page).to have_selector('.avatars--current-local-avatar', text: 'none')

      # Gravatars not rendered
      expect(page).to have_no_selector('.form--fieldset-legend', text: 'GRAVATAR')

      # Attach a new invalid image
      find('#avatar_file_input').set File.join(image_base_path, 'invalid.txt')

      # Expect error
      expect(page).to have_selector('.form--label.-error')
      expect(page).to have_selector('.avatars--error-pane', text: 'Allowed formats are jpg, png, gif')

      # Attach new image
      visit avatar_management_path
      expect(page).to have_selector('.avatars--current-local-avatar', text: 'none')
      find('#avatar_file_input').set File.join(image_base_path, 'too_big.jpg')

      # Expect not error, since ng-file-upload resizes the image
      expect(page).to have_no_selector('.form--label.-error')
      expect(page).to have_no_selector('.avatars--error-pane span')

      # Expect preview
      expect(page).to have_selector('.preview img')

      # Click button
      click_on 'Update'

      # Expect avatar rendered
      expect(page).to have_selector('.form--fieldset-legend', text: 'CUSTOM AVATAR')
      avatar_tag = find('.avatars--current-local-avatar img')
      expect(avatar_tag[:src]).to include user_avatar_path(target_user)

      # Expect the avatar to be resized
      avatar_path = target_user.local_avatar_attachment.file.path
      image_data = FastImage.new avatar_path
      expect(image_data.size).to eq [128, 128]
      expect(%i(jpeg jpg)).to include image_data.type

      # Delete the avatar
      find('.avatars--local-avatar-delete-link').click
      page.driver.browser.switch_to.alert.accept

      expect(page).to have_selector('.avatars--current-local-avatar', text: 'none', wait: 20)
    end
  end

  describe 'both local avatars enabled' do
    let(:enable_gravatars) { true }
    let(:enable_local_avatars) { true }

    it 'renders both sections' do
      visit avatar_management_path

      # Gravatar
      expect(page).to have_selector('.form--fieldset-legend', text: 'GRAVATAR')
      expect(page).to have_selector('.avatars--current-gravatar')

      # Local
      expect(page).to have_selector('.form--fieldset-legend', text: 'CUSTOM AVATAR')
      expect(page).to have_selector('.avatars--current-local-avatar', text: 'none')
    end
  end
end
