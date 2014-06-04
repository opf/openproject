module OmniAuth
  class FlexibleBuilder < Builder
    def use(middleware, *args, &block)
      middleware.extend FlexibleStrategyClass
      super(middleware, *args, &block)
    end
  end
end
