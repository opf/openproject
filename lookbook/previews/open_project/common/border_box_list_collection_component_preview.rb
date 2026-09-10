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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class BorderBoxListCollectionComponentPreview < ViewComponent::Preview
      # @label Default (static)
      # Emission-only preview: a page-level collection of two rows, each a
      # section-shaped BorderBoxListComponent box. Dragging needs a real
      # browser and a page-level sortable-lists root outside the box being
      # previewed, so this only shows the declared wiring — the same
      # dual-role composition `Settings::ProjectCustomFieldSections::IndexComponent`
      # uses: the collection owns the page-level root and the "section" row
      # type, each row box owns its own "custom_field" list. Uses
      # `render_with_template` (rather than nested `render` calls in Ruby)
      # because `ViewComponent::Preview#render` only produces a real
      # component tree at the top level of a preview method — nested calls
      # from inside a captured slot block return an unrendered descriptor.
      def default
        render_with_template
      end
    end
  end
end
