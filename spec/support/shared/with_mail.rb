RSpec.configure do |config|
  config.around(:each) do |example|
    config = example.metadata[:with_mail]
    if example.metadata.key?(:with_mail) && !config
      value = ActionMailer::Base.perform_deliveries

      begin
        ActionMailer::Base.perform_deliveries = false

        example.run
      ensure
        ActionMailer::Base.perform_deliveries = value
      end
    else
      example.run
    end
  end
end
