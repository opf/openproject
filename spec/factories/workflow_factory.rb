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

FactoryBot.define do
  factory :workflow do
    # A workflow belongs to a variant. `type:` / `type_id:` are kept as aliases so the many
    # call sites that name a type keep reading naturally: a type contributes its base variant.
    transient do
      type { nil }
      type_id { nil }
    end

    old_status factory: :status
    new_status factory: :status
    role factory: :project_role
    type_variant do
      case type
      when TypeVariant
        type
      when Type
        type.default_variant
      else
        type_id ? Type.find(type_id).default_variant : association(:type_variant)
      end
    end

    factory :workflow_with_default_status do
      old_status factory: :default_status
    end
  end
end
