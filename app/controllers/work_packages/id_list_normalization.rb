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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Shared normalization for the array-valued id list parameters used by the
# work package move and bulk-edit forms. They are pulled out of the generic
# scalar "none"/blank attribute transforms and normalized here instead:
#   * blank selection  -> nil  (leave the existing associations untouched)
#   * "none" selected  -> []   (clear all associations, even if ids are selected too)
#   * ids              -> [ids]
module WorkPackages::IdListNormalization
  extend ActiveSupport::Concern

  ID_LIST_ATTRIBUTES = %i[target_version_ids observed_in_version_ids label_ids].freeze

  included do
    private

    def extract_normalized_id_lists(attributes)
      ID_LIST_ATTRIBUTES
        .index_with { |key| normalized_id_list(attributes.delete(key)) }
        .compact
    end

    def normalized_id_list(raw)
      values = Array(raw).compact_blank
      return [] if values.include?("none")

      values.presence
    end
  end
end
