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

module Redmine
  module Acts
    module Customizable
      module HumanAttributeName
        # If a model acts_as_customizable it will inject attributes like 'custom_field_1' into itself.
        # Using this method, they can now be i18ned same as every other attribute. This is for example
        # for error messages following the format of '%{attribute} %{message}' where `attribute` is resolved
        # by calling IncludingClass.human_attribute_name
        def human_attribute_name(attribute, options = {})
          match = /\Acustom_field_(?<id>\d+)\z/.match(attribute)

          if match
            CustomField.find_by(id: match[:id]).name
          else
            super
          end
        end
      end
    end
  end
end
