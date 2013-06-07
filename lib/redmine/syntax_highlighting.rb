#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
        # use CodeRay to scan normal text, since it's smart enough to find
        # the correct source encoding before passing it to ERB::Util.html_escape
        def highlight_by_filename(text, filename)
          language = ::CodeRay::FileType[filename]
          language ? ::CodeRay.scan(text, language).html.html_safe : ERB::Util.h(::CodeRay.scan(text, :text).text)
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
