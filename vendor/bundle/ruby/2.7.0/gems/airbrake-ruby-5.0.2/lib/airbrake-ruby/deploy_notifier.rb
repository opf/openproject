module Airbrake
  # DeployNotifier sends deploy information to Airbrake. The information
  # consists of:
  # - environment
  # - username
  # - repository
  # - revision
  # - version
  #
  # @api public
  # @since v3.2.0
  class DeployNotifier
    include Inspectable

    def initialize
      @config = Airbrake::Config.instance
      @sender = SyncSender.new
    end

    # @see Airbrake.notify_deploy
    def notify(deploy_info)
      promise = @config.check_configuration
      return promise if promise.rejected?

      promise = Airbrake::Promise.new
      deploy_info[:environment] ||= @config.environment
      @sender.send(
        deploy_info,
        promise,
        URI.join(@config.host, "api/v4/projects/#{@config.project_id}/deploys"),
      )

      promise
    end
  end
end
