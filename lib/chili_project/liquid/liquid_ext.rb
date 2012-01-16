#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ChiliProject
  module Liquid
    module LiquidExt
      ::Liquid::Block.send(:include, Block)
      ::Liquid::Context.send(:include, Context)
      # Required until https://github.com/Shopify/liquid/pull/87 got merged upstream
      ::Liquid::Strainer.send(:include, Strainer)
    end
  end
end
