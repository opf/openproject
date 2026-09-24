# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  module Hierarchy
    class UpdateListItemContract < DryApplicationContract
      params do
        required(:item).filled(type?: CustomField::Hierarchy::Item)
        required(:label).filled(:string)
      end

      rule(:item) do
        key.failure(:not_persisted) if value.new_record?
        key.failure(:root_item) if value.root?
        key.failure(:nesting_not_allowed) if value.parent.present? && !value.parent.root?
      end

      rule(:label) do
        next if schema_error?(:item)

        key.failure(:not_unique) if values[:item].siblings.exists?(label: value)
      end
    end
  end
end
