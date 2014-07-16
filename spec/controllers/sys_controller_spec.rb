require 'spec_helper'

module OpenProjectRepositoryAuthenticationSpecs
  describe SysController do
    let(:commit_role) { FactoryGirl.create(:role, :permissions => [:commit_access,
                                                                  :browse_repository]) }
    let(:browse_role) { FactoryGirl.create(:role, :permissions => [:browse_repository]) }
    let(:guest_role) { FactoryGirl.create(:role, :permissions => []) }
    let(:valid_user_password) { "Top Secret Password" }
    let(:valid_user) { FactoryGirl.create(:user, :login => "johndoe",
                                                 :password => valid_user_password,
                                                 :password_confirmation => valid_user_password)}

    before(:each) do
      FactoryGirl.create(:non_member, :permissions => [:browse_repository])
      DeletedUser.first # creating it first in order to avoid problems with should_receive

      random_project = FactoryGirl.create(:project, :is_public => false)
      @member = FactoryGirl.create(:member, :user => valid_user,
                                            :roles => [browse_role],
                                            :project => random_project)
      Setting.stub(:sys_api_key).and_return("12345678")
      Setting.stub(:sys_api_enabled?).and_return(true)
      Setting.stub(:repository_authentication_caching_enabled?).and_return(true)
    end

    describe :repo_auth, "for valid login, but no access to repo_auth" do
      before(:each) do
        @key = Setting.sys_api_key
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
        post "repo_auth", { :key => @key, :repository => "without-access", :method => "GET" }
      end

      it "should respond 403 not allowed" do
        response.code.should == "403"
        response.body.should == "Not allowed"
      end
    end

    describe :repo_auth, "for valid login and user has browse repository permission (role reporter) for project" do
      before(:each) do
        @key = Setting.sys_api_key
        @project = FactoryGirl.create(:project, :is_public => false)
        @member = FactoryGirl.create(:member, :user => valid_user,
                                              :roles => [browse_role],
                                              :project => @project)
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
      end

      it "should respond 200 okay dokay for GET" do
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "GET" }
        response.code.should == "200"
      end

      it "should respond 403 not allowed for POST" do
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "POST" }
        response.code.should == "403"
      end
    end

    describe :repo_auth, "for valid login and user has commit access permission (role developer) for project" do
      before(:each) do
        @key = Setting.sys_api_key
        @project = FactoryGirl.create(:project, :is_public => false)
        @member = FactoryGirl.create(:member, :user => valid_user,
                                              :roles => [commit_role],
                                              :project => @project )
        valid_user.save
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
      end

      it "should respond 200 okay dokay for GET" do
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "GET" }
        response.code.should == "200"
      end

      it "should respond 200 okay dokay for POST" do
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "POST" }
        response.code.should == "200"
      end
    end

    describe :repo_auth, "for invalid login and user has role manager for project" do
      before(:each) do
        @key = Setting.sys_api_key
        @project = FactoryGirl.create(:project, :is_public => false )
        @member = FactoryGirl.create(:member, :user => valid_user,
                                              :roles => [commit_role],
                                              :project => @project)
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password + "made invalid")
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "GET" }
      end

      it "should respond 401 auth required" do
        response.code.should == "401"
      end
    end

    describe :repo_auth, "for valid login and user is not member for project" do
      before(:each) do
        @key = Setting.sys_api_key
        @project = FactoryGirl.create(:project, :is_public => false)
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "GET" }
      end

      it "should respond 403 not allowed" do
        response.code.should == "403"
      end
    end

    describe :repo_auth, "for valid login and project is public" do
      before(:each) do
        @key = Setting.sys_api_key
        @project = FactoryGirl.create(:project, :is_public => true)

        random_project = FactoryGirl.create(:project, :is_public => false)
        @member = FactoryGirl.create(:member, :user => valid_user,
                                              :roles => [browse_role],
                                              :project => random_project)

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
        post "repo_auth", { :key => @key, :repository => @project.identifier, :method => "GET" }
      end

      it "should respond 200 OK" do
        response.code.should == "200"
      end
    end

    describe :repo_auth, "for invalid credentials" do
      before(:each) do
        @key = Setting.sys_api_key
        post "repo_auth", { :key => @key, :repository => "any-repo", :method => "GET" }
      end

      it "should respond 401 auth required" do
        response.code.should == "401"
        response.body.should == "Authorization required"
      end
    end

    describe :repo_auth, "for invalid api key" do
      before(:each) do
        @key = "invalid"
      end

      it "should respond 403 for valid username/password" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(valid_user.login, valid_user_password)
        post "repo_auth", { :key => @key, :repository => "any-repo", :method => "GET" }
        response.code.should == "403"
        response.body.should == "Access denied. Repository management WS is disabled or key is invalid."
      end

      it "should respond 403 for invalid username/password" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("invalid", "invalid")
        post "repo_auth", { :key => @key, :repository => "any-repo", :method => "GET" }
        response.code.should == "403"
        response.body.should == "Access denied. Repository management WS is disabled or key is invalid."
      end
    end

    before(:each) do
      Rails.cache.clear
      Rails.cache.stub(:kind_of?).with(anything).and_return(false)
    end

    describe :cached_user_login do
      let(:cache_key) { OpenProject::RepositoryAuthentication::CACHE_PREFIX +
                        Digest::SHA1.hexdigest("#{valid_user.login}#{valid_user_password}") }
      let(:cache_expiry) { OpenProject::RepositoryAuthentication::CACHE_EXPIRES_AFTER }

      it "should call user_login only once when called twice" do
        controller.should_receive(:user_login).once.and_return(valid_user)
        2.times { controller.send(:cached_user_login, valid_user.login, valid_user_password) }
      end

      it "should return the same as user_login for valid creds" do
        controller.send(:cached_user_login, valid_user.login, valid_user_password).should ==
        controller.send(:user_login, valid_user.login, valid_user_password)
      end

      it "should return the same as user_login for invalid creds" do
        controller.send(:cached_user_login, "invalid", "invalid").should ==
          controller.send(:user_login, "invalid", "invalid")
      end

      it "should use cache" do
        # allow the cache to return something reasonable for
        # other requests, while ensuring that it is not queried
        # with the cache key in question

        # unfortunately, and_call_original currently fails
        Rails.cache.stub(:fetch) do |*args|
          args.first.should_not == cache_key

          name = args.first.split("/").last
          Marshal.dump(Setting.send(:find_or_default, name).value)
        end
        #Rails.cache.should_receive(:fetch).with(anything).and_call_original
        Rails.cache.should_receive(:fetch).with(cache_key, :expires_in => cache_expiry) \
                                          .and_return(Marshal.dump(valid_user.id.to_s))
        controller.send(:cached_user_login, valid_user.login, valid_user_password)
      end

      describe "with caching disabled" do
        before do
          Setting.stub(:repository_authentication_caching_enabled?).and_return(false)
        end

        it 'should not use a cache' do
          # allow the cache to return something reasonable for
          # other requests, while ensuring that it is not queried
          # with the cache key in question
          #
          # unfortunately, and_call_original currently fails
          Rails.cache.stub(:fetch) do |*args|
            args.first.should_not == cache_key

            name = args.first.split("/").last
            Marshal.dump(Setting.send(:find_or_default, name).value)
          end

          controller.send(:cached_user_login, valid_user.login, valid_user_password)
        end
      end
    end
  end
end
