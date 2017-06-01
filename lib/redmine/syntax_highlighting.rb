#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module SyntaxHighlighting
    class << self
      attr_reader :highlighter
      delegate :highlight_by_filename, :highlight_by_language, to: :highlighter

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
        # use CodeRay to scan normal text, since it's smart enough to find
        # the correct source encoding before passing it to ERB::Util.html_escape
        def highlight_by_filename(text, filename)
          language = ::CodeRay::FileType[filename]
          if language
            ::CodeRay.scan(text, language).html.html_safe
          else
            ERB::Util.h(::CodeRay.scan(text, :text).text)
          end
        end

        # Highlights +text+ using +language+ syntax
        # Should not return outer pre tag
        def highlight_by_language(text, language)
          ::CodeRay.scan(text, language).html(line_numbers: :inline, wrap: :span)
        end
      end
    end
  end

  SyntaxHighlighting.highlighter = 'CodeRay'
end
