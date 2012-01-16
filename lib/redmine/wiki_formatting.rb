#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module WikiFormatting
    @@formatters = {}

    class << self
      def map
        yield self
      end

      def register(name, formatter, helper)
        raise ArgumentError, "format name '#{name}' is already taken" if @@formatters[name.to_s]
        @@formatters[name.to_s] = {:formatter => formatter, :helper => helper}
      end

      def formatter_for(name)
        entry = @@formatters[name.to_s]
        (entry && entry[:formatter]) || Redmine::WikiFormatting::NullFormatter::Formatter
      end

      def helper_for(name)
        entry = @@formatters[name.to_s]
        (entry && entry[:helper]) || Redmine::WikiFormatting::NullFormatter::Helper
      end

      def format_names
        @@formatters.keys.map
      end

      def to_html(format, text, options = {}, &block)
        formatter_for(format).new(text).to_html
      end
    end
  end
end
