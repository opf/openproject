module ChiliProject
  module Liquid
    module LiquidExt
      ::Liquid::Context.send(:include, Context)
    end
  end
end
