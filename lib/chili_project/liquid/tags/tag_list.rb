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

module ChiliProject::Liquid::Tags
  class TagList < Tag
    include ActionView::Helpers::TagHelper

    def render(context)
      content_tag('p', "Tags:") +
      content_tag('ul',
        ::Liquid::Template.tags.keys.sort.collect {|tag_name|
          content_tag('li', content_tag('code', h(tag_name)))
        }.join('')
      )
    end
  end
end