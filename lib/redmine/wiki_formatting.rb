# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module WikiFormatting
    @@formatters = {}

    class << self
      def map
        yield self
      end
      
      def register(name, formatter, helper)
        raise ArgumentError, "format name '#{name}' is already taken" if @@formatters[name.to_sym]
        @@formatters[name.to_sym] = {:formatter => formatter, :helper => helper}
      end
      
      def formatter_for(name)
        entry = @@formatters[name.to_sym]
        (entry && entry[:formatter]) || Redmine::WikiFormatting::NullFormatter::Formatter
      end
      
      def helper_for(name)
        entry = @@formatters[name.to_sym]
        (entry && entry[:helper]) || Redmine::WikiFormatting::NullFormatter::Helper
      end
      
      def format_names
        @@formatters.keys.map
      end
      
      def to_html(format, text, options = {}, &block)
        formatter_for(format).new(text).to_html(&block)
      end
    end
    
    # Default formatter module
    module NullFormatter
      class Formatter
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        
        def initialize(text)
          @text = text
        end
        
        def to_html(*args)
          simple_format(auto_link(CGI::escapeHTML(@text)))
        end
      end
      
      module Helper
        def wikitoolbar_for(field_id)
        end
      
        def heads_for_wiki_formatter
        end
      
        def initial_page_content(page)
          page.pretty_title.to_s
        end
      end
    end
  end
end
