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

module OpenProject::TextFormatting
  module Filters
    class MentionFilter < HTML::Pipeline::Filter
      include ERB::Util
      include ActionView::Helpers::UrlHelper
      include OpenProject::ObjectLinking
      include OpenProject::StaticRouting::UrlHelpers

      def call
        doc.search('mention').each do |mention|
          mention.replace mention_anchor(mention)
        end

        doc
      end

      private

      def mention_anchor(mention)
        principal = principal_from_mention(mention)

        if principal.is_a?(Group)
          group_mention(principal)
        else
          user_mention(principal)
        end
      end

      def user_mention(user)
        link_to_user(user,
                     only_path: context[:only_path],
                     class: 'user-mention')
      end

      def group_mention(group)
        content_tag :span,
                    group.name,
                    title: I18n.t(:label_group_named, name: group.name),
                    class: 'user-mention'
      end

      def principal_from_mention(mention)
        principal_class = case mention.attributes['data-type'].value
                          when 'user'
                            User
                          when 'group'
                            Group
                          else
                            raise ArgumentError
                          end

        principal_class.find_by(id: mention.attributes['data-id'].value) || mention.text
      end

      # For link_to
      def controller; end
    end
  end
end
