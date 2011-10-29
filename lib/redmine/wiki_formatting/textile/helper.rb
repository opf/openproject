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

module Redmine
  module WikiFormatting
    module Textile
      module Helper
        def wikitoolbar_for(field_id)
          heads_for_wiki_formatter
          url = url_for(:controller => 'help', :action => 'wiki_syntax')
          help_link = link_to(l(:setting_text_formatting), url,
                              :onclick => "window.open(\"#{ url }\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;",
                              :tabindex => -1)

          javascript_tag("var wikiToolbar = new jsToolBar($('#{field_id}')); wikiToolbar.setHelpLink('#{escape_javascript help_link}'); wikiToolbar.draw();")
        end

        def initial_page_content(page)
          "h1. #{@page.pretty_title}"
        end

        def heads_for_wiki_formatter
          unless @heads_for_wiki_formatter_included
            content_for :header_tags do
              javascript_include_tag('jstoolbar/jstoolbar') +
              javascript_include_tag('jstoolbar/textile') +
              javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}") +
              stylesheet_link_tag('jstoolbar')
            end
            @heads_for_wiki_formatter_included = true
          end
        end
      end
    end
  end
end
