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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  module Hierarchy
    class UpdateItemContract < Dry::Validation::Contract
      params do
        required(:item).filled(type?: CustomField::Hierarchy::Item)
        optional(:label).filled(:string)
        optional(:short).filled(:string)
      end

      rule(:item) do
        key.failure("must exist") if value.new_record?
        key.failure("must not be a root item") if value.root?
      end

      rule(:label) do
        next unless key?

        if CustomField::Hierarchy::Item.exists?(parent_id: values[:item].parent_id, label: value)
          key.failure("must be unique at the same hierarchical level")
        end
      end
    end
  end
end
