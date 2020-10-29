require 'active_support'
require 'active_support/deprecation'
require 'active_record/connection_adapters/nulldb_adapter'

module NullDB
  LEGACY_ACTIVERECORD = 
    Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.2.0')

  class Configuration < Struct.new(:project_root); end

  class << self
    def configure
      @configuration = Configuration.new.tap {|c| yield c}
    end

    def configuration
      if @configuration.nil?
        raise "NullDB not configured. Require a framework, ex 'nulldb/rails'"
      end

      @configuration
    end

    def nullify(options={})
      begin
        @prev_connection = ActiveRecord::Base.connection_pool.try(:spec)
      rescue ActiveRecord::ConnectionNotEstablished
      end
      ActiveRecord::Base.establish_connection(options.merge(:adapter => :nulldb))
    end

    def restore
      if @prev_connection
        ActiveRecord::Base.establish_connection(@prev_connection.config)
      end
    end

    def checkpoint
      ActiveRecord::Base.connection.checkpoint!
    end
  end
end
