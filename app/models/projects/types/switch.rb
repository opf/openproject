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

module Projects
  module Types
    # Which member of a type family a project should use. Backs the switch
    # dialog: the form binds to it, and it owns the preview of the switch it
    # describes.
    class Switch
      include ActiveModel::Model

      attr_accessor :project, :source
      attr_writer :target_id

      validate :target_selectable

      def target_id
        @target_id.presence&.to_i
      end

      def target
        return @target if defined?(@target)

        @target = target_id && ::Type.find_by(id: target_id)
      end

      def available_targets
        source.family
      end

      # The dialog opens on the member the project uses now, so applying without
      # choosing anything is a visible no-op rather than an empty field.
      def selected_target
        target || source
      end

      private

      def target_selectable
        if target_id.blank?
          errors.add(:target_id, :blank)
        elsif available_targets.exclude?(target)
          errors.add(:target_id, :not_in_family)
        elsif target == source
          errors.add(:target_id, :unchanged)
        end
      end
    end
  end
end
