module ChiliProject
  module Liquid
    module LiquidExt
      ::Liquid::Block.send(:include, Block)
      ::Liquid::Context.send(:include, Context)
    end
  end
end
