RSpec.configure do |config|
  # Rails 5.1+ safely shares the database connection between the app and test
  # threads. So RSpec thread and Puma thread share the same db connection,
  # meaning running tests in transaction is ok as the transaction will be
  # visible for both.

  # Run every test method within a transaction
  config.use_transactional_fixtures = true
  config.around(:each, use_transactional_fixtures: false) do |example|
    self.use_transactional_tests = false
    example.run
    self.use_transactional_tests = true
  end
end
