#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module TextFormattingHelper
  include OpenProject::TextFormatting
  extend Forwardable

  def_delegators :current_formatting_helper,
                 :wikitoolbar_for

  def preview_context(object, project = nil)
    if object.new_record?
      project_preview_context(object, project)
    elsif object.is_a? Message
      message_preview_context(object)
    else
      object_preview_context(object, project)
    end
  end

  # TODO remove
  def current_formatting_helper
    helper_class = OpenProject::TextFormatting::Formats.rich_helper
    helper_class.new(self)
  end

  def project_preview_context(object, project)
    relevant_project = if project
                         project
                       elsif object.respond_to?(:project) && object.project
                         object.project
                       end

    return nil unless relevant_project

    API::V3::Utilities::PathHelper::ApiV3Path
      .project(relevant_project.id)
  end

  def message_preview_context(message)
    API::V3::Utilities::PathHelper::ApiV3Path
      .post(message.id)
  end

  def object_preview_context(object, project)
    paths = API::V3::Utilities::PathHelper::ApiV3Path

    if paths.respond_to?(object.class.name.underscore.singularize)
      paths.send(object.class.name.underscore.singularize, object.id)
    else
      project_preview_context(object, project)
    end
  end

  def truncate_formatted_text(text, length: 120, replace_newlines: true)
    # rubocop:disable Rails/OutputSafety
    stripped_text = strip_tags(format_text(text.to_s))

    stripped_text = if length
                      truncate_multiline(stripped_text, length)
                    else
                      stripped_text
                    end
                      .strip

    if replace_newlines
      stripped_text
        .gsub(/[\r\n]+/, '<br />')
    else
      stripped_text
    end
      .html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def truncate_multiline(string, length)
    if string.to_s.length > length
      "#{string[0, length]}..."
    else
      string
    end
  end
end
