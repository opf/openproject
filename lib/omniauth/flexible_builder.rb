module OmniAuth
  class FlexibleBuilder < Builder
    def use(middleware, *args, &block)
      super FlexibleStrategyClass.new(middleware), *args, &block
    end
  end
end
