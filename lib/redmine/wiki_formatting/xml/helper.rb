#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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