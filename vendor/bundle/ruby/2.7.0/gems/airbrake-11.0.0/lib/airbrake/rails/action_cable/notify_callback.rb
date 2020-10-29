# frozen_string_literal: true

module Airbrake
  module Rails
    module ActionCable
      # @since v8.3.0
      # @api private
      class NotifyCallback
        def self.call(channel, block)
          block.call
        rescue Exception => ex # rubocop:disable Lint/RescueException
          notice = Airbrake.build_notice(ex)
          notice[:context][:component] = 'action_cable'
          notice[:context][:action] = channel.channel_name
          Airbrake.notify(notice)

          raise ex
        end
      end
    end
  end
end
