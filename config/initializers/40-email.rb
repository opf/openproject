# Loads action_mailer settings from email.yml
# and turns deliveries on if configuration file is found

filename = File.join(File.dirname(__FILE__), '..', 'email.yml')
if File.file?(filename)
  mailconfig = YAML::load_file(filename)

  if mailconfig.is_a?(Hash) && mailconfig.has_key?(Rails.env)
    # Enable deliveries
    ActionMailer::Base.perform_deliveries = true
    
    mailconfig[Rails.env].each do |k, v|
      v.symbolize_keys! if v.respond_to?(:symbolize_keys!)
      ActionMailer::Base.send("#{k}=", v)
    end
  end
end
