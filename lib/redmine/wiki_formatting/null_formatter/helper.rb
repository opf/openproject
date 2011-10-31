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
    module NullFormatter
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