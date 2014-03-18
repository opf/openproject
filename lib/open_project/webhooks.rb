module OpenProject
  module Webhooks
    require "open_project/webhooks/engine"
    require "open_project/webhooks/hook"

    @@registered_hooks = []

    ##
    # Returns a list of currently active webhooks.
    def self.registered_hooks
      @@registered_hooks.dup
    end

    ##
    # Registeres a webhook having name and a callback.
    # The name will be part of the webhook-url and may be used to unregister a webhook later.
    # The callback is executed with two parameters when the webhook was called.
    #    The parameters are the hook object, an environment-variables hash and a params hash of the current request.
    # The callback may return an Integer, which is interpreted as a http return code.
    #
    # Returns the newly created hook
    def self.register_hook(name, &callback)
      raise "A hook named '#{name}' is already registered!" if find(name)
      Rails.logger.warn "hook registered"
      hook = Hook.new(name, &callback)
      @@registered_hooks << hook
      hook
    end

    # Unregisters a webhook. Might be usefull for tests only, because routes can not
    # be redrawn in a running instance
    def self.unregister_hook(name)
      hook = find(name)
      raise "A hook named '#{name}' was not registered!" unless find(name)
      @@registered_hooks.delete hook
    end

    def self.find(name)
      @@registered_hooks.find {|h| h.name == name}
    end
  end
end
