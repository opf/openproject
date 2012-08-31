#-- encoding: UTF-8
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

module Redmine::Acts::Journalized
  module Permissions
    # Default implementation of journal editing permission
    # Is overridden if defined in the journalized model directly
    def journal_editable_by?(user)
      return true if user.admin?
      if respond_to? :editable_by?
        editable_by? user
      else
        permission = :"edit_#{self.class.to_s.pluralize.downcase}"
        p = @project || (project if respond_to? :project)
        options = { :global => p.present? }
        user.allowed_to? permission, p, options
      end
    end
  end
end
