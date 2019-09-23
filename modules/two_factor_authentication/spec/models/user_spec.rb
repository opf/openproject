require_relative '../spec_helper'

module OpenProject::TwoFactorAuthentication::Patches
  module UserSpec
    describe User, with_2fa_ee: true do
      def create_user(auth_source_id = nil)
        @user = FactoryBot.build(:user)
        @username = @user.login
        @password = @user.password
        @user.auth_source_id = auth_source_id
        @user.save!
        allow_any_instance_of(User).to receive_messages(:allowed_to? => true, :active? => true)
      end

      def create_user_with_auth_source
        auth_source = AuthSource.new :name => "test"
        create_user auth_source.id
      end

      def valid_login
        login_with @username, @password
      end

      def invalid_login
        login_with @username, @password + "INVALID"
      end

      def login_with login, password
        User.try_to_login(login, password)
      end

      before (:each) do
        create_user
      end

      describe '#try_to_login', "with valid username but invalid pwd" do
        it "should return nil" do
          expect(invalid_login).to eq(nil)
        end

        it "should return the user" do
          expect(valid_login).to eq(@user)
        end
      end
    end
  end
end
