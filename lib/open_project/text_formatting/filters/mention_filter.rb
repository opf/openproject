#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module OpenProject::TextFormatting
  module Filters
    class MentionFilter < HTML::Pipeline::Filter
      include ERB::Util
      include ActionView::Helpers::UrlHelper
      include OpenProject::ObjectLinking
      include OpenProject::StaticRouting::UrlHelpers

      def call
        doc.search("mention").each do |mention|
          anchor = mention_anchor(mention)
          mention.replace(anchor) if anchor
        end

        doc
      end

      private

      def mention_anchor(mention)
        mention_instance = class_from_mention(mention)

        case mention_instance
        when Group
          group_mention(mention_instance)
        when User
          user_mention(mention_instance)
        when WorkPackage
          work_package_mention(mention_instance)
        else
          mention_instance
        end
      end

      def user_mention(user)
        link_to_user(user,
                     only_path: context[:only_path],
                     class: "user-mention")
      end

      def group_mention(group)
        link_to_group(group,
                      only_path: context[:only_path],
                      class: "user-mention")
      end

      def work_package_mention(work_package)
        link_to("##{work_package.id}",
                work_package_path_or_url(id: work_package.id, only_path: context[:only_path]),
                class: "issue work_package preview-trigger")
      end

      def class_from_mention(mention)
        mention_class = case mention.attributes["data-type"].value
                        when "user"
                          User
                        when "group"
                          Group
                        when "work_package"
                          WorkPackage
                        else
                          raise ArgumentError
                        end

        mention_class.find_by(id: mention_id(mention)) || mention.text
      end

      # For link_to
      def controller; end

      def mention_id(mention)
        attribute_value = mention.attributes["data-id"]&.value

        id_match = attribute_value&.match(/\d+/)

        id_match ? id_match[0] : nil
      end
    end
  end
end
