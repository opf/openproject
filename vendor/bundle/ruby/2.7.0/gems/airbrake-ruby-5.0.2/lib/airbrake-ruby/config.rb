module Airbrake
  # Represents the Airbrake config. A config contains all the options that you
  # can use to configure an Airbrake instance.
  #
  # @api public
  # @since v1.0.0
  class Config
    # @return [Integer] the project identificator. This value *must* be set.
    # @api public
    attr_accessor :project_id

    # @return [String] the project key. This value *must* be set.
    # @api public
    attr_accessor :project_key

    # @return [Hash] the proxy parameters such as (:host, :port, :user and
    #   :password)
    # @api public
    attr_accessor :proxy

    # @return [Logger] the default logger used for debug output
    # @api public
    attr_reader :logger

    # @return [String] the version of the user's application
    # @api public
    attr_accessor :app_version

    # @return [Hash{String=>String}] arbitrary versions that your app wants to
    #   track
    # @api public
    # @since v2.10.0
    attr_accessor :versions

    # @return [Integer] the max number of notices that can be queued up
    # @api public
    attr_accessor :queue_size

    # @return [Integer] the number of worker threads that process the notice
    #   queue
    # @api public
    attr_accessor :workers

    # @return [String] the host, which provides the API endpoint to which
    #   exceptions should be sent
    # @api public
    attr_accessor :host

    # @since v5.0.0
    alias error_host host
    # @since v5.0.0
    alias error_host= host=

    # @return [String] the host, which provides the API endpoint to which
    #   APM data should be sent
    # @api public
    # @since v5.0.0
    attr_accessor :apm_host

    # @return [String, Pathname] the working directory of your project
    # @api public
    attr_accessor :root_directory

    # @return [String, Symbol] the environment the application is running in
    # @api public
    attr_accessor :environment

    # @return [Array<String,Symbol,Regexp>] the array of environments that
    #   forbids sending exceptions when the application is running in them.
    #   Other possible environments not listed in the array will allow sending
    #   occurring exceptions.
    # @api public
    attr_accessor :ignore_environments

    # @return [Integer] The HTTP timeout in seconds.
    # @api public
    attr_accessor :timeout

    # @return [Array<String, Symbol, Regexp>] the keys, which should be
    #   filtered
    # @api public
    # @since v4.15.0
    attr_accessor :allowlist_keys

    # @return [Array<String, Symbol, Regexp>] the keys, which should be
    #   filtered
    # @api public
    # @since v4.15.0
    attr_accessor :blocklist_keys

    # @return [Boolean] true if the library should attach code hunks to each
    #   frame in a backtrace, false otherwise
    # @api public
    # @since v2.5.0
    attr_accessor :code_hunks

    # @return [Boolean] true if the library should send route performance stats
    #   to Airbrake, false otherwise
    # @api public
    # @since v3.2.0
    attr_accessor :performance_stats

    # @return [Integer] how many seconds to wait before sending collected route
    #   stats
    # @api private
    # @since v3.2.0
    attr_accessor :performance_stats_flush_period

    # @return [Boolean] true if the library should send SQL stats to Airbrake,
    #   false otherwise
    # @api public
    # @since v4.6.0
    attr_accessor :query_stats

    # @return [Boolean] true if the library should send job/queue/worker stats
    #   to Airbrake, false otherwise
    # @api public
    # @since v4.12.0
    attr_accessor :job_stats

    # @return [Boolean] true if the library should send error reports to
    #   Airbrake, false otherwise
    # @api public
    # @since 5.0.0
    attr_accessor :error_notifications

    # @return [String] the host such as which should be used for fetching remote
    #   configuration options (example: "https://bucket-name.s3.amazonaws.com")
    attr_accessor :remote_config_host

    class << self
      # @return [Config]
      attr_writer :instance

      # @return [Config]
      def instance
        @instance ||= new
      end
    end

    # @param [Hash{Symbol=>Object}] user_config the hash to be used to build the
    #   config
    # rubocop:disable Metrics/AbcSize
    def initialize(user_config = {})
      self.proxy = {}
      self.queue_size = 100
      self.workers = 1
      self.code_hunks = true
      self.logger = ::Logger.new(File::NULL).tap { |l| l.level = Logger::WARN }
      self.project_id = user_config[:project_id]
      self.project_key = user_config[:project_key]
      self.error_host = 'https://api.airbrake.io'
      self.apm_host = 'https://api.airbrake.io'
      self.remote_config_host = 'https://v1-production-notifier-configs.s3.amazonaws.com'

      self.ignore_environments = []

      self.timeout = user_config[:timeout]

      self.blocklist_keys = []
      self.allowlist_keys = []

      self.root_directory = File.realpath(
        (defined?(Bundler) && Bundler.root) ||
        Dir.pwd,
      )

      self.versions = {}
      self.performance_stats = true
      self.performance_stats_flush_period = 15
      self.query_stats = true
      self.job_stats = true
      self.error_notifications = true

      merge(user_config)
    end
    # rubocop:enable Metrics/AbcSize

    # The full URL to the Airbrake Notice API. Based on the +:error_host+ option.
    # @return [URI] the endpoint address
    def error_endpoint
      @error_endpoint ||=
        begin
          self.error_host = ('https://' << error_host) if error_host !~ %r{\Ahttps?://}
          api = "api/v3/projects/#{project_id}/notices"
          URI.join(error_host, api)
        end
    end

    # Sets the logger. Never allows to assign `nil` as the logger.
    # @return [Logger] the logger
    def logger=(logger)
      @logger = logger || @logger
    end

    # Merges the given +config_hash+ with itself.
    #
    # @example
    #   config.merge(host: 'localhost:8080')
    #
    # @return [self] the merged config
    def merge(config_hash)
      config_hash.each_pair { |option, value| set_option(option, value) }
      self
    end

    # @return [Boolean] true if the config meets the requirements, false
    #   otherwise
    def valid?
      validate.resolved?
    end

    # @return [Promise]
    # @see Validator.validate
    def validate
      Validator.validate(self)
    end

    # @return [Promise]
    # @see Validator.check_notify_ability
    def check_notify_ability
      Validator.check_notify_ability(self)
    end

    # @return [Boolean] true if the config ignores current environment, false
    #   otherwise
    def ignored_environment?
      check_notify_ability.rejected?
    end

    # @return [Promise] resolved promise if config is valid & can notify,
    #   rejected otherwise
    def check_configuration
      promise = validate
      return promise if promise.rejected?

      check_notify_ability
    end

    # @return [Promise] resolved promise if neither of the performance options
    #   reject it, false otherwise
    def check_performance_options(resource)
      promise = Airbrake::Promise.new

      if !performance_stats
        promise.reject("The Performance Stats feature is disabled")
      elsif resource.is_a?(Airbrake::Query) && !query_stats
        promise.reject("The Query Stats feature is disabled")
      elsif resource.is_a?(Airbrake::Queue) && !job_stats
        promise.reject("The Job Stats feature is disabled")
      else
        promise
      end
    end

    private

    def set_option(option, value)
      __send__("#{option}=", value)
    rescue NoMethodError
      raise Airbrake::Error, "unknown option '#{option}'"
    end
  end
end
