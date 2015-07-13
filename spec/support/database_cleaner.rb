RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.prepend_before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  # bring before's and afters in line
  # https://gist.github.com/stevenharman/2321262#comment-1202772
  # https://gist.github.com/mockdeep/9904695
  config.prepend_before(:each, type: :feature) do
    DatabaseCleaner.strategy = :deletion
  end

  config.append_after(:each, type: :feature) do
    DatabaseCleaner.strategy = :transaction
  end
end

# config.before(:suite) do
#   DatabaseCleaner.clean_with :truncation
# end

# config.before(:each) do |example|
#   DatabaseCleaner.strategy = if example.metadata[:js]
#                                # JS => doesn't share connections => can't use transactions
#                                # truncations seem to fail more often + they are slower
#                                :deletion
#                              else
#                                # No JS/Devise => run with Rack::Test => transactions are ok
#                                :transaction
#                              end

#   DatabaseCleaner.start
# end

# config.after(:each) do
#   DatabaseCleaner.clean
# end
