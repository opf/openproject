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

module CustomFields::Inputs::Base::Autocomplete::UserQueryUtils
  def user_autocomplete_options
    {
      component: "opce-user-autocompleter",
      defaultData: false,
      placeholder: I18n.t(:label_user_search),
      resource:,
      url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
      filters:,
      searchKey: search_key,
      inputValue: custom_input_value,
      focusDirectly: false,
      appendTo: append_to # unlike for the decorated autocompleters, this option has to be passed as camelCase key here!
    }
  end

  def resource
    "principals"
  end

  def search_key
    "any_name_attribute"
  end

  def filters
    [
      { name: "type", operator: "=", values: ["User", "Group", "PlaceholderUser"] },
      { name: "member", operator: "=", values: [@object.id.to_s] },
      { name: "status", operator: "!", values: [Principal.statuses["locked"].to_s] }
    ]
  end
end
