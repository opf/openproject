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
  module WikiFormatting
    module Xml
      module Helper
        def wikitoolbar_for(field_id)
          heads_for_wiki_formatter
          javascript_tag("tinyMCE.execCommand(\"mceAddControl\", true, \"#{field_id}\");")
        end

        def initial_page_content(page)
          ("<h1>".html_safe + page.pretty_title.to_s + "<h1>".html_safe).html_safe
        end

        def heads_for_wiki_formatter
          unless @heads_for_wiki_formatter_included
            content_for :header_tags do
              tinymce_assets + tinymce
            end
            @heads_for_wiki_formatter_included = true
          end
        end
      end
    end
  end
end

# register test macro
Redmine::WikiFormatting::Macros.register do
  desc <<-EOF
    Display a kitten.
  EOF

  macro :rndimg do |obj, args, options|
    if options[:edit]
      image_tag "http://www.adoptny.org/wp-content/themes/adoptny/img/placeholder.png", :alt => 'A kitten'
    else
      width = args.first || 400
      height = args.second || 401
      url = "http://tessenow.org/rndimg/#{width}/#{height}"
      url << "/#{args[2]}" if args[2]
      image_tag url, :alt => 'A random image'
    end
  end
end