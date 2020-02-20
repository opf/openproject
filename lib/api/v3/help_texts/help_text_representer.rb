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

module API
  module V3
    module HelpTexts
      class HelpTextRepresenter < ::API::Decorators::Single
        self_link path: :help_text,
                  id_attribute: :id,
                  title_getter: ->(*) { nil }

        link :editText do
          if current_user.admin?
            {
              href: edit_attribute_help_text_path(represented.id),
              type: 'text/html'
            }
          end
        end

        property :id
        property :attribute_name,
                 as: :attribute,
                 getter: ->(*) {
                   ::API::Utilities::PropertyNameConverter.from_ar_name(attribute_name)
                 }
        property :attribute_caption
        property :attribute_scope,
                 as: :scope
        property :help_text,
                 exec_context: :decorator,
                 getter: ->(*) {
                   ::API::Decorators::Formattable.new(represented.help_text)
                 }

        def _type
          'HelpText'
        end
      end
    end
  end
end
