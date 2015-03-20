# Force the usage of config/database.yml instead of DATABASE_URL.
# Used so that query parameters from the DATABASE_URL are correctly used (e.g. SSL settings).
config = YAML.load(ERB.new(File.read(Rails.root.join("config/database.yml"))).result)[Rails.env.to_s]
ActiveRecord::Base.establish_connection config
