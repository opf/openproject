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
  class VariableList < Tag
    include ActionView::Helpers::TagHelper

    def render(context)
      out = ''
      context.environments.first.keys.sort.each do |liquid_variable|
        next if liquid_variable == 'text' # internal variable
        out << content_tag('li', content_tag('code', h(liquid_variable)))
      end if context.environments.present?

      content_tag('p', "Variables:") + content_tag('ul', out)
    end
  end
end
