require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'tmpdir'
require 'securerandom'

def env_db
  (ENV['DB'] || :mysql).to_sym
end

db_config = File.expand_path('database.yml', File.dirname(__FILE__))
ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(db_config)).result)

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

ActiveRecord::Base.establish_connection(env_db)
ActiveRecord::Migration.verbose = false

require 'test_models'
begin
  require 'minitest'
rescue LoadError
  puts 'Failed to load the minitest gem; built-in version will be used.'
end
require 'minitest/autorun'
require 'minitest/great_expectations'
require 'mocha/setup'

class MiniTest::Spec
  before do
    ENV['FLOCK_DIR'] = Dir.mktmpdir
    Tag.delete_all
    TagAudit.delete_all
    Label.delete_all
  end
  after do
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
  end
end

