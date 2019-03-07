RSpec.configure do |config|

  # Since Rails 5.1., we can force the application server and capybara to share the same connection,
  # which results in database_cleaner no longer being necessary.
  # This will only work with a server that works in single mode (e.g., Puma)
  # We're still using database_cleaner in cucumber however, so we can use it to ensure we run
  # with a clean database (which use_transactional_fixtures does not ensure).
  # c.f., spec/support/database_cleaner
  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
