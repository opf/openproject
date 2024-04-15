require "spec_helper"

RSpec.describe AvatarHelper, with_settings: { protocol: "http" } do
  include AngularHelper

  let(:user) { build_stubbed(:user) }
  let(:mail_digest) { Digest::MD5.hexdigest(user.mail) }
  let(:avatar_stub) { build_stubbed(:avatar_attachment) }

  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { false }
  let(:plugin_settings) do
    {
      "enable_gravatars" => enable_gravatars,
      "enable_local_avatars" => enable_local_avatars
    }
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
            .and_return(plugin_settings)

    allow(user).to receive(:local_avatar_attachment).and_return avatar_stub
  end

  def expected_user_avatar_tag(user)
    principal = {
      href: "/api/v3/users/#{user.id}",
      name: user.name,
      id: user.id
    }

    angular_component_tag "opce-principal",
                          inputs: {
                            principal:,
                            hideName: true,
                            nameClasses: "",
                            link: nil,
                            title: user.name,
                            size: "default"
                          }
  end

  def local_expected_url(user)
    user_avatar_url(user)
  end

  def gravatar_expected_url(digest, options = {})
    ssl = !!options[:ssl]

    host =
      if ssl
        "https://secure.gravatar.com"
      else
        "http://gravatar.com"
      end

    "#{host}/avatar/#{digest}?default=404&secure=#{ssl}"
  end

  describe "gravatar and local" do
    context "when enabled" do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { true }

      it "returns the image attached to the user" do
        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end

      it "returns the gravatar image if no image uploaded for the user" do
        allow(user).to receive(:local_avatar_attachment).and_return nil

        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end
    end

    context "when gravatar disabled" do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { true }

      it "returns blank if image attached to the user but gravatars disabled" do
        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end
    end

    context "when all disabled" do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { false }

      it "returns blank" do
        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end
    end
  end

  describe "#avatar_url" do
    context "when enabled" do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { true }

      it "returns the url to the image attached to the user" do
        expect(helper.avatar_url(user)).to eq(local_expected_url(user))
      end

      it "returns the gravatar url if no image uploaded for the user" do
        allow(user).to receive(:local_avatar_attachment).and_return nil

        expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest))
      end
    end

    context "when gravatar disabled" do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { true }

      it "returns the url if image attached to the user but gravatars disabled" do
        expect(helper.avatar_url(user)).to eq(local_expected_url(user))
      end
    end

    context "when all disabled" do
      let(:enable_gravatars) { false }
      let(:enable_local_avatars) { false }

      it "returns blank" do
        expect(helper.avatar_url(user)).to eq ""
      end
    end
  end

  context "when gravatar enabled" do
    let(:enable_gravatars) { true }
    let(:enable_local_avatars) { false }

    describe "ssl dependent on protocol settings" do
      context "with https protocol", with_config: { https: true } do
        it "is set to secure if protocol is 'https'" do
          expect(helper.default_gravatar_options[:secure]).to be true
        end
      end

      context "with http protocol", with_config: { https: false } do
        it "is set to unsecure if protocol is 'http'" do
          expect(helper.default_gravatar_options[:secure]).to be false
        end
      end
    end

    context "with http", with_config: { https: false } do
      it "returns a gravatar image tag if a user is provided" do
        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end

      it "returns a gravatar url if a user is provided" do
        expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest))
      end
    end

    context "with https", with_config: { https: true } do
      it "returns a gravatar image tag without ssl if the request was no ssl required" do
        expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
      end

      it "returns a gravatar image tag with ssl if the request was ssl required" do
        expect(helper.avatar_url(user)).to eq(gravatar_expected_url(mail_digest, ssl: true))
      end
    end

    it "returns an empty string if a non parsable (e-mail) string is provided" do
      expect(helper.avatar("just the name")).to eq("")
    end

    it "returns an empty string if nil is provided" do
      expect(helper.avatar(nil)).to eq("")
    end

    it "returns an empty string if a parsable e-mail with default avatar is provided" do
      mail = "<e-mail@mail.de>"

      expect(helper.avatar(mail)).to eq("")
    end

    it "returns an empty string if a non parsable (e-mail) string url is provided" do
      expect(helper.avatar_url("just the name")).to eq("")
    end

    it "returns an empty string if nil url is provided" do
      expect(helper.avatar_url(nil)).to eq("")
    end
  end

  context "when all disabled" do
    let(:enable_gravatars) { false }
    let(:enable_local_avatars) { false }

    it "returns an empty string for avatar if gravatar is disabled" do
      expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
    end

    it "returns an empty string for avatar_url if gravatar is disabled" do
      expect(helper.avatar_url(user)).to eq("")
    end
  end

  context "with system user" do
    let(:user) { User.system }

    it "renders the avatar as user type (Regression #37278)" do
      expect(helper.avatar(user)).to be_html_eql(expected_user_avatar_tag(user))
    end
  end
end
