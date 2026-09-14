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

module WorkPackageTypes
  # The admin routes carry an optional `variants/:variant_id` under a type. Reading the pair back
  # is the inverse of TypeVariant#path_args, and every controller mounted there needs it.
  module AddressesVariant
    extend ActiveSupport::Concern

    private

    # The variant the URL names. Absent the segment, the URL is about the type itself, and the
    # configuration answering for it is its base variant.
    #
    # +among+ narrows what the id may name, for routes that only address some of a type's
    # variants.
    def addressed_variant(among: nil)
      return addressed_type.default_variant if params[:variant_id].blank?

      (among || ::TypeVariant).find(params.expect(:variant_id))
    end

    # Overridden by controllers that have already loaded it.
    def addressed_type
      ::Type.find(params.expect(:type_id))
    end
  end
end
