require 'delegate'

module OmniAuth
  class FlexibleStrategyClass < SimpleDelegator
    def new(app, *args, &block)
      if args.last.is_a?(Hash) && args.last.include?(:providers)
        opts = args.pop
        providers[__getobj__] << opts.delete(:providers)
      end

      __getobj__.new(app, *args, &block).tap do |strategy|
        strategy.extend FlexibleStrategy
        strategy.providers = providers[__getobj__].map(&:call).flatten
      end
    end

    def providers
      @@providers ||= Hash.new([])
    end
  end

  module FlexibleStrategy
    def providers=(providers)
      @providers = providers
    end

    def on_auth_path?
      (match_provider! || false) && super
    end

    ##
    # Tries to match the request path of the current request with one of the registered providers.
    # If a match is found the strategy is intialised with that provider to handle the request.
    def match_provider!
      return false unless @providers

      @provider = providers.find do |p|
        (current_path =~ /#{path_for_provider(p.to_hash[:name])}/) == 0
      end

      if @provider
        options.merge! provider.to_hash
      end

      @provider
    end

    def path_for_provider(name)
      "#{path_prefix}/#{name}"
    end

    def providers
      @providers
    end

    def provider
      @provider
    end

    def dup
      super.tap do |s|
        s.extend FlexibleStrategy
        s.providers = providers
      end
    end
  end
end
