module OkComputer
  class SequelCheck < Check
    attr_reader :migration_directory

    # Public: Initialize the SequelCheck with the database and/or the migration_directory.
    #
    # Defaults to Sequel:Model.db and 'db/migration' respectively. "database" option can be a Proc so that
    # Sequel can be instantiated later in the boot process.
    def initialize(options={})
      @database = options[:database] || -> { ::Sequel::Model.db }
      @migration_directory = options[:migration_directory] || 'db/migrate'
    end

    # Public: Return the schema version of the database
    def check
      mark_message "Schema is #{'not ' unless is_current?}up to date"
    rescue ConnectionFailed => e
      mark_failure
      mark_message "Error: '#{e}'"
    end

    def database
      @database.is_a?(Proc) ? @database.call : @database
    end

    # Public: The scema version of the app's database
    #
    # Returns a String with the version number
    def is_current?
      ::Sequel.extension(:migration)
      ::Sequel::Migrator.is_current?(database, migration_directory)
    rescue => e
      raise ConnectionFailed, e
    end

    ConnectionFailed = Class.new(StandardError)
  end
end
