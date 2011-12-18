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

module ChiliProject::Liquid::Tags
  class Identity < Tag
    def initialize(tag_name, markup, tokens)
      @tag_name = tag_name
      @markup = markup
      @tokens = tokens
      super
    end

    def render(context)
      "{% #{@tag_name} %}"
    end
  end
end