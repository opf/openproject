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

module CustomFields
  class BaseContract < ::ModelContract
    include RequiresAdminGuard

    attribute :editable
    attribute :type
    attribute :field_format
    attribute :is_filter
    attribute :is_for_all
    attribute :is_required
    attribute :max_length
    attribute :min_length
    attribute :name
    attribute :possible_values
    attribute :regexp
    attribute :searchable
    attribute :admin_only
    attribute :default_value
    attribute :possible_values
    attribute :multi_value
    attribute :content_right_to_left
    attribute :custom_field_section_id
    attribute :allow_non_open_versions
  end
end
