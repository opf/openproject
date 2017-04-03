RSpec.configure do |config|
  config.before(:each) do
    # Clear any mail deliveries
    # This happens automatically for :mailer specs
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear

    RequestStore.clear!
  end

  config.append_after(:each) do
    # Cleanup after specs changing locale explicitly or
    # by calling code in the app setting changing the locale.
    I18n.locale = :en

    # Set the class instance variable @current_user to nil
    # to avoid having users from one spec present in the next
    ::User.instance_variable_set(:@current_user, nil)
  end

  # We don't want this to be reported on CI as it breaks the build
  unless ENV['CI']
    config.after(:suite) do
      [User, Project, WorkPackage].each do |cls|
        next if cls.count == 0
        raise <<-EOS
          Your specs left a #{cls} in the DB
          Did you use before(:all) instead of before
          or forget to kill the instances in a after(:all)?
        EOS
      end
    end
  end
end
