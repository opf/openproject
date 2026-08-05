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

# Shared normalization for the array-valued +target_version_ids+ and
# +category_ids+ parameters used by the work package move and bulk-edit forms.
# They are pulled out of the generic scalar "none"/blank attribute transforms
# (which are built for scalar values) and normalized here instead.
module WorkPackages::MultiValueAttributeNormalization
  extend ActiveSupport::Concern

  included do
    private

    # Mirrors the magic values of the deprecated scalar counterpart for an
    # array-valued id parameter:
    #   * blank selection  -> nil  (leave the existing set untouched)
    #   * "none" selection -> []   (clear the set)
    #   * an id            -> [id]
    def normalized_multi_value_ids(raw)
      values = Array(raw).compact_blank
      values == ["none"] ? [] : values.presence
    end
  end
end
