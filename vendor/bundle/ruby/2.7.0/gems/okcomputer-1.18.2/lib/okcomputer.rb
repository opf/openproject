require "ok_computer/configuration" # must come before engine
require "ok_computer/engine" if defined?(Rails)
require "ok_computer/check"
require "ok_computer/check_collection"
require "ok_computer/registry"
require "ok_computer/legacy_rails_controller_support"

# and the built-in checks
require "ok_computer/built_in_checks/size_threshold_check"
require "ok_computer/built_in_checks/http_check"
require "ok_computer/built_in_checks/ping_check"

require "ok_computer/built_in_checks/action_mailer_check"
require "ok_computer/built_in_checks/active_record_check"
require "ok_computer/built_in_checks/active_record_migrations_check"
require "ok_computer/built_in_checks/app_version_check"
require "ok_computer/built_in_checks/cache_check"
require "ok_computer/built_in_checks/default_check"
require "ok_computer/built_in_checks/delayed_job_backed_up_check"
require "ok_computer/built_in_checks/directory_check"
require "ok_computer/built_in_checks/generic_cache_check"
require "ok_computer/built_in_checks/elasticsearch_check"
require "ok_computer/built_in_checks/mongoid_check"
require "ok_computer/built_in_checks/neo4j_check"
require "ok_computer/built_in_checks/mongoid_replica_set_check"
require "ok_computer/built_in_checks/optional_check"
require "ok_computer/built_in_checks/rabbitmq_check"
require "ok_computer/built_in_checks/redis_check"
require "ok_computer/built_in_checks/resque_backed_up_check"
require "ok_computer/built_in_checks/resque_down_check"
require "ok_computer/built_in_checks/resque_scheduler_check"
require "ok_computer/built_in_checks/resque_failure_threshold_check"
require "ok_computer/built_in_checks/ruby_version_check"
require "ok_computer/built_in_checks/sequel_check"
require "ok_computer/built_in_checks/sidekiq_latency_check"
require "ok_computer/built_in_checks/solr_check"

OkComputer::Registry.register "default", OkComputer::DefaultCheck.new

if defined?(ActiveRecord)
  OkComputer::Registry.register "database", OkComputer::ActiveRecordCheck.new
elsif defined?(Sequel)
  OkComputer::Registry.register "database", OkComputer::SequelCheck.new
end
