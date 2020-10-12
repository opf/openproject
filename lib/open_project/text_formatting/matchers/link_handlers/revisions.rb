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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class Revisions < Base
      ##
      # Match revision links.
      # Condition: Separator is r
      # Condition: Prefix is nil
      def applicable?
        matcher.prefix.nil? && matcher.sep == 'r'
      end

      #
      # Examples:
      #
      # r11, r13
      def call
        # don't handle link unless repository exists
        return nil unless project && project.repository

        changeset = project.repository.find_changeset_by_name(matcher.identifier)

        if changeset
          link_to(h("#{matcher.project_prefix}r#{matcher.identifier}"),
                  { only_path: context[:only_path], controller: '/repositories', action: 'revision', project_id: project, rev: changeset.revision },
                  class: 'changeset',
                  title: truncate_single_line(changeset.comments, length: 100))
        end
      end
    end
  end
end
