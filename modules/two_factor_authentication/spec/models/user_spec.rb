require_relative "../spec_helper"

module OpenProject::TwoFactorAuthentication::Patches
  module UserSpec
    RSpec.describe User do
      def create_user(ldap_auth_source_id = nil)
        @user = build(:user)
        @username = @user.login
        @password = @user.password
        @user.ldap_auth_source_id = ldap_auth_source_id
        @user.save!
      end

      def create_user_with_auth_source
        auth_source = LdapAuthSource.new name: "test"
        create_user auth_source.id
      end

      def valid_login
        login_with @username, @password
      end

      def invalid_login
        login_with @username, @password + "INVALID"
      end

      def login_with(login, password)
        User.try_to_login(login, password)
      end

      before (:each) do
        create_user
      end

      describe "#try_to_login", "with valid username but invalid pwd" do
        it "returns nil" do
          expect(invalid_login).to be_nil
        end

        it "returns the user" do
          expect(valid_login).to eq(@user)
        end
      end
    end
  end
end
