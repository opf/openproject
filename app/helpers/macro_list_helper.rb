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

module MacroListHelper
  def macro_list_render_usage(descriptor)
    opening = "&lt;#{descriptor.qname}"
    params = ''
    tailing = ''
    content = ''
    closing = '/&gt;'
    # add common opf:escape param
    params << '&nbsp;[opf:escape]'
    unless descriptor.params.nil? and not descriptor.with_content?
      if descriptor.params
        descriptor.params.each do |param|
          params << '&nbsp;'
          params << '[' if param[:optional]
          params << param[:id].to_s
          unless param[:type] == :boolean
            params << '="..."'
          end
          params << ']' if param[:optional]
        end
      end
      if descriptor.with_content?
        content << '<br/>&nbsp;&nbsp;'
        content << '[' if descriptor.with_content[:optional]
        content << '...content...'
        content << ']' if descriptor.with_content[:optional]
        content << '<br/>'
        tailing = '&gt;'
        closing = "&lt;/#{descriptor.qname}&gt;"
      end
    end
    "<code>#{opening}#{params}#{tailing}#{content}#{closing}</code>".html_safe
  end
end
