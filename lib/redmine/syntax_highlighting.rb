# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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
  module SyntaxHighlighting
    
    class << self
      attr_reader :highlighter
      delegate :highlight_by_filename, :highlight_by_language, :to => :highlighter
      
      def highlighter=(name)
        if name.is_a?(Module)
          @highlighter = name
        else
          @highlighter = const_get(name)
        end
      end
    end
    
    module CodeRay
      require 'coderay'
      require 'coderay/helpers/file_type'
      
      class << self
        # Highlights +text+ as the content of +filename+
        # Should not return line numbers nor outer pre tag
        def highlight_by_filename(text, filename)
          language = ::CodeRay::FileType[filename]
          language ? ::CodeRay.scan(text, language).html : ERB::Util.h(text)
        end
        
        # Highlights +text+ using +language+ syntax
        # Should not return outer pre tag
        def highlight_by_language(text, language)
          ::CodeRay.scan(text, language).html(:line_numbers => :inline, :wrap => :span)
        end
      end
    end
  end
  
  SyntaxHighlighting.highlighter = 'CodeRay'
end
