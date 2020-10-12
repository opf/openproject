#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module TextFormatting
    include ::OpenProject::TextFormatting::Truncation

    # Formats text according to system settings.
    # 2 ways to call this method:
    # * with a String: format_text(text, options)
    # * with an object and one of its attribute: format_text(issue, :description, options)
    def format_text(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      case args.size
      when 1
        attribute = nil
        object = options[:object]
        text = args.shift
      when 2
        object = args.shift
        attribute = args.shift
        text = object.send(attribute).to_s
      else
        raise ArgumentError, 'invalid arguments to format_text'
      end
      return '' if text.blank?

      project = options.delete(:project) { @project || object.try(:project) }
      only_path = options.delete(:only_path) != false
      current_user = options.delete(:current_user) { User.current }

      plain = ::OpenProject::TextFormatting::Formats.plain?(options.delete(:format))

      Renderer.format_text text,
                           options.merge(
                             plain: plain,
                             object: object,
                             request: try(:request),
                             current_user: current_user,
                             attribute: attribute,
                             only_path: only_path,
                             project: project
                           )
    end
  end
end
