require 'spec_helper'

describe AvatarHelper, type: :helper, with_settings: { protocol: 'http' } do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:mail_digest) { Digest::MD5.hexdigest(user.mail) }
  let(:avatar_stub) { FactoryBot.build_stubbed(:avatar_attachment) }

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

    allow(user).to receive(:local_avatar_attachment).and_return avatar_stub
  end

  def local_expected_user_avatar_tag(user)
    tag_options = { 'data-user-id': user.id,
                    'data-user-name': user.name,
                    'data-class-list': 'avatar' }

    content_tag 'user-avatar', '', tag_options
  end

  def local_expected_url(user)
    user_avatar_url(user)
  end

  def default_expected_user_avatar_tag(user)
    tag_options = { 'data-use-fallback': "true",
                    'data-user-name': user.name,
                    'data-class-list': 'avatar avatar-default' }

    content_tag 'user-avatar', '', tag_options
  end

  def gravatar_expected_user_avatar_tag(digest, options = {})
    tag_options = { 'data-user-id': user.id,
                    'data-user-name': user.name,
                    'data-class-list': 'avatar avatar--gravatar-image avatar--fallback' }

    content_tag 'user-avatar', '', tag_options
  end

  def gravatar_expected_image_tag(digest, options = {})
    tag_options = options.reverse_merge(title: user.name,
                                        alt: 'Gravatar',
                                        class: 'avatar avatar--gravatar-image avatar--fallback').delete_if { |key, value| value.nil? || key == :ssl }

    image_tag gravatar_expected_url(digest, options), tag_options
  end

  def gravatar_expected_url(digest, options = {})
    ssl = !!options[:ssl]

    host =
      if ssl
        'https://secure.gravatar.com'
      else
        'http://gravatar.com'
      end

    "#{host}/avatar/#{digest}?default=404&secure=#{ssl}"
  end

  describe 'gravatar and local' do
    context 'when enabled' do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { true }
      it "should return the image attached to the user" do
        expect(helper.avatar(user)).to be_html_eql(local_expected_user_avatar_tag(user))
      end

      it "should return the gravatar image if no image uploaded for the user" do
        allow(user).to receive(:local_avatar_attachment).and_return nil

        expect(helper.avatar(user)).to be_html_eql(gravatar_expected_user_avatar_tag(mail_digest))
      end
    end

    context 'when gravatar disabled' do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { true }
      it "should return blank if image attached to the user but gravatars disabled" do
        expect(helper.avatar(user)).to be_html_eql(local_expected_user_avatar_tag(user))
      end
    end

    context 'when all disabled' do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { false }

      it "should return blank" do
        expect(helper.avatar(user)).to be_html_eql(default_expected_user_avatar_tag(user))
      end
    end
  end

  describe '#avatar_url' do
    context 'when enabled' do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { true }
      it "should return the url to the image attached to the user" do
        expect(helper.avatar_url(user)).to eq(local_expected_url(user))
      end

      it "should return the gravatar url if no image uploaded for the user" do
        allow(user).to receive(:local_avatar_attachment).and_return nil

        expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest))
      end
    end

    context 'when gravatar disabled' do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { true }
      it "should return the url if image attached to the user but gravatars disabled" do
        expect(helper.avatar_url(user)).to eq(local_expected_url(user))
      end
    end

    context 'when all disabled' do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { false }

      it "should return blank" do
        expect(helper.avatar_url(user)).to eq ''
      end
    end
  end

  describe 'gravatar' do
    context 'when enabled' do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { false }
      describe 'ssl dependent on protocol settings' do
        context 'with https protocol', with_settings: { protocol: 'https' } do
          it "should be set to secure if protocol is 'https'" do
            expect(helper.default_gravatar_options[:secure]).to be true
          end
        end

        context 'with http protocol', with_settings: { protocol: 'http' } do
          it "should be set to unsecure if protocol is 'http'" do
            expect(helper.default_gravatar_options[:secure]).to be false
          end
        end
      end

      context 'with http', with_settings: { protocol: 'http' } do
        it 'should return a gravatar image tag if a user is provided' do
          expect(helper.avatar(user)).to be_html_eql(gravatar_expected_user_avatar_tag(mail_digest))
        end

        it 'should return a gravatar url if a user is provided' do
          expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest))
        end
      end

      context 'with https', with_settings: { protocol: 'https' } do
        it 'should return a gravatar image tag with ssl if the request was ssl required' do
          expect(helper.avatar(user)).to be_html_eql(gravatar_expected_user_avatar_tag(mail_digest, ssl: true))
        end

        it 'should return a gravatar image tag with ssl if the request was ssl required' do
          expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest, ssl: true))
        end
      end

      it 'should return an empty string if a non parsable (e-mail) string is provided' do
        expect(helper.avatar('just the name')).to eq('')
      end

      it 'should return an empty string if nil is provided' do
        expect(helper.avatar(nil)).to eq('')
      end

      it 'should return an empty string if a parsable e-mail with default avatar is provided' do
        mail = '<e-mail@mail.de>'

        expect(helper.avatar(mail)).to eq('')
      end

      it 'should return a gravatar url if a parsable e-mail string is provided' do
        mail = '<e-mail@mail.de>'
        digest = Digest::MD5.hexdigest('e-mail@mail.de')

        expect(helper.avatar_url(mail)).to eq(gravatar_expected_url(digest))
      end

      it 'should return an empty string if a non parsable (e-mail) string is provided' do
        expect(helper.avatar_url('just the name')).to eq('')
      end

      it 'should return an empty string if nil is provided' do
        expect(helper.avatar_url(nil)).to eq('')
      end
    end
  end

  context 'when all disabled' do
    let(:enable_gravatars) { false }
    let(:enable_local_avatars) { false }

    it 'should return an empty string if gravatar is disabled' do
      expect(helper.avatar(user)).to be_html_eql(default_expected_user_avatar_tag(user))
    end

    it 'should return an empty string if gravatar is disabled' do
      expect(helper.avatar_url(user)).to eq('')
    end
  end
end
