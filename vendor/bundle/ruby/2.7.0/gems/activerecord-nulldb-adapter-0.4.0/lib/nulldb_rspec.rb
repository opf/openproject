require 'active_record/connection_adapters/nulldb_adapter'

module NullDB
  module RSpec
  end
end

module NullDB::RSpec::NullifiedDatabase
  NullDBAdapter = ActiveRecord::ConnectionAdapters::NullDBAdapter

  class HaveExecuted

    def initialize(entry_point)
      @entry_point = entry_point
    end

    def matches?(connection)
      log = connection.execution_log_since_checkpoint
      if @entry_point == :anything
        not log.empty?
      else
        log.include?(NullDBAdapter::Statement.new(@entry_point))
      end
    end

    def description
      "connection should execute #{@entry_point} statement"
    end

    def failure_message
      " did not execute #{@entry_point} statement when it should have"
    end

    def negative_failure_message
      " executed #{@entry_point} statement when it should not have"
    end
  end

  def self.globally_nullify_database
    block = lambda { |config| nullify_database(config) }
    if defined?(RSpec)
      RSpec.configure(&block)
    else
      Spec::Runner.configure(&block)
    end
  end

  def self.contextually_nullify_database(context)
    nullify_database(context)
  end

  # A matcher for asserting that database statements have (or have not) been
  # executed.  Usage:
  #
  #   ActiveRecord::Base.connection.should have_executed(:insert)
  #
  # The types of statement that can be matched mostly mirror the public
  # operations available in
  # ActiveRecord::ConnectionAdapters::DatabaseStatements:
  # - :select_one
  # - :select_all
  # - :select_value
  # - :insert
  # - :update
  # - :delete
  # - :execute
  #
  # There is also a special :anything symbol that will match any operation.
  def have_executed(entry_point)
    HaveExecuted.new(entry_point)
  end

  private

  def self.included(other)
    if nullify_contextually?(other)
      contextually_nullify_database(other)
    else
      globally_nullify_database
    end
  end

  def self.nullify_contextually?(other)
    if defined?(RSpec)
      other < RSpec::Core::ExampleGroup
    else
      other.is_a? Spec::ExampleGroup
    end
  end

  def self.nullify_database(receiver)
    receiver.before :all do
      ActiveRecord::Base.establish_connection(:adapter => :nulldb)
    end

    receiver.before :each do
      ActiveRecord::Base.connection.checkpoint!
    end

    receiver.after :all do
      ActiveRecord::Base.establish_connection(:test)
    end
  end
end
