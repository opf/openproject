#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
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

module Acts::Journalized
  module Permissions
    # Default implementation of journal editing permission
    # Is overridden if defined in the journalized model directly
    def journal_editable_by?(journal, user)
      return true if user.admin?

      editable = if respond_to? :editable_by?
                   editable_by?(user)
                 else
                   # TODO: Also check if we are a work package and then check this? Will have to revisit
                   p = @project || (project if respond_to? :project)

                   # None of the permissions that are checked here are global permissions, so they would all be checked
                   # against any project in the existing logic. Do we really want that here? Why should a journal entry
                   # be editbale if the user has the permission within any project?
                   #
                   # Permissions were checked with:
                   #    Zeitwerk::Loader.eager_load_all
                   #    ObjectSpace.each_object(Class).select { |c| c.included_modules.include? Acts::Journalized::Permissions }.map { |cls| cls.new.send(:journable_edit_permission) }
                   #
                   # I think it makes sense to return false here if no project is present and not check on any project?

                   if p
                     user.allowed_in_project(journable_edit_permission, p)
                   else
                     user.allowed_in_any_project?(journable_edit_permission)
                   end
                 end

      editable && journal.user_id == user.id
    end

    private

    def journable_edit_permission
      if respond_to? :journal_permission
        journal_permission
      else
        :"edit_#{self.class.to_s.pluralize.underscore}"
      end
    end
  end
end
