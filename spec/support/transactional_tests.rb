RSpec.configure do |config|
  # Rails 5.1+ safely shares the database connection between the app and test
  # threads. So RSpec thread and Puma thread share the same db connection,
  # meaning running tests in transaction is ok as the transaction will be
  # visible for both.

  # Run every test method within a transaction
  config.use_transactional_fixtures = true
end
