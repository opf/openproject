require 'open_project/plugins/auth_plugin'

module OmniAuth
  module FlexibleStrategyClass
    def new(app, *args, &block)
      super(app, *args, &block).tap do |strategy|
        strategy.extend FlexibleStrategy
      end
    end
  end

  module FlexibleStrategy
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
      @providers ||= OpenProject::Plugins::AuthPlugin.providers_for(self.class)
    end

    def provider
      @provider
    end

    def providers=(providers)
      @providers = providers
    end

    def dup
      super.tap do |s|
        s.extend FlexibleStrategy
        s.providers = providers
      end
    end
  end
end
