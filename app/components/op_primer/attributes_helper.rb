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

module OpPrimer
  # Drop-in replacement for `Primer::AttributesHelper` that treats the Stimulus
  # `controller` data attribute as plural. Stimulus supports multiple
  # controllers on one element (space-separated `data-controller="a b"`), but
  # upstream Primer omits `controller` from its plural data attributes, so
  # `merge_data` would silently drop a caller's controller when a component
  # merges in its own. Treating it as plural concatenates them instead.
  module AttributesHelper
    include Primer::AttributesHelper

    PLURAL_DATA_ATTRIBUTES = (Primer::AttributesHelper::PLURAL_DATA_ATTRIBUTES + %i[controller]).freeze

    def merge_data(*hashes)
      merge_prefixed_attribute_hashes(*hashes, prefix: :data, plural_keys: PLURAL_DATA_ATTRIBUTES)
    end
  end
end
