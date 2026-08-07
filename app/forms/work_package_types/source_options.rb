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
  # The copy and link dialogs offer the same sources, so they read one list here
  # and cannot drift apart.
  module SourceOptions
    private

    def source_options
      Type.global.in_family_order.reject { |source| source == type }
    end

    # Variants carry their parent in the composite name; the current type's own
    # parent is additionally flagged as the most likely source.
    def label_for(source)
      return source.composite_name unless parent?(source)

      "#{source.composite_name}#{I18n.t('types.edit.reuse_mode.parent_suffix')}"
    end

    def parent?(source)
      source == type.parent
    end
  end
end
