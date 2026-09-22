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
  # Legacy custom option ids and migrated item ids cannot collide: the migration
  # advances hierarchical_items' sequence past every custom option id that ever
  # existed, so an id at or below that watermark is always a legacy one.
  class LegacyOptionIdResolver
    class << self
      def resolve(custom_field:, id:)
        resolve_all(custom_field:, ids: [id]).first
      end

      def resolve_all(custom_field:, ids:)
        return ids unless custom_field.list?

        mapping = CustomField::LegacyOptionMapping
                    .where(custom_field_id: custom_field.id, custom_option_id: ids)
                    .pluck(:custom_option_id, :hierarchical_item_id)
                    .to_h

        ids.map { |id| mapping[id.to_i]&.to_s || id }
      end
    end
  end
end
