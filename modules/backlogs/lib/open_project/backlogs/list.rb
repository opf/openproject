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

module OpenProject::Backlogs::List
  extend ActiveSupport::Concern

  included do
    acts_as_list touch_on_update: false, scope: %i[project_id backlog_bucket_id sprint_id]

    # acts as list adds a before destroy hook which messes
    # with the parent_id_was value
    skip_callback(:destroy, :before, :reload)

    include InstanceMethods
  end

  module InstanceMethods
    def move_after(position: nil, prev_id: nil)
      # Remove so the potential 'prev' has a correct position
      remove_from_list
      reload
      cast_position = ActiveRecord::Type::Integer.new.cast(position)
      id_or_position = cast_position ? { position: cast_position - 1 } : { id: prev_id }

      prev = acts_as_list_list.find_by(**id_or_position)

      if prev.blank?
        # If prev is blank, it means the element should be inserted at the first position.
        insert_at
        move_to_top
      else
        # There's a valid predecessor
        insert_at(prev.position + 1)
      end
    end

    protected

    # Override acts_as_list implementation to avoid it calling save.
    # Calling save would remove the changes/saved_changes information.
    def set_list_position(new_position, _raise_exception_if_save_fails = false) # rubocop:disable Style/OptionalBooleanParameter
      update_columns(position: new_position)
    end
  end
end
