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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class WorkPackages < Base
      ##
      # Match work package links.
      # Condition: Separator is #|##|###
      # Condition: Prefix is nil
      def applicable?
        %w(# ## ###).include?(matcher.sep) && matcher.prefix.nil?
      end

      #
      # Examples:
      #
      # #1234, ##1234, ###1234
      def call
        oid = matcher.identifier.to_i
        work_package = find_work_package(oid)
        return nil unless work_package

        # Avoid cyclic dependencies between linking two work packages
        return nil if cyclic_inclusion?(work_package)

        render_work_package_link(work_package)
      end

      private

      def cyclic_inclusion?(work_package)
        description = context[:attribute] == :description
        same_object = context[:object] && context[:object].id == work_package.id
        link_with_description = matcher.sep == "###"

        description && same_object && link_with_description || context[:no_nesting]
      end

      def render_work_package_link(work_package)
        if matcher.sep == '##'
          return work_package_quick_info(work_package, only_path: context[:only_path])
        elsif matcher.sep == '###' && !context[:no_nesting]
          return work_package_quick_info_with_description(work_package, only_path: context[:only_path])
        end

        if matcher.sep == '#' || (matcher.sep == '###' && context[:no_nesting])
          link_to("#{matcher.sep}#{work_package.id}",
                  work_package_path_or_url(id: work_package.id, only_path: context[:only_path]),
                  class: work_package_css_classes(work_package),
                  title: "#{truncate(work_package.subject, escape: false, length: 100)} (#{work_package.status.try(:name)})")
        end
      end

      def find_work_package(oid)
        WorkPackage
          .visible
          .includes(:status)
          .references(:statuses)
          .find_by(id: oid)
      end
    end
  end
end
