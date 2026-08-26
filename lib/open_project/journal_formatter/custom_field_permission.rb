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

# Shared by formatters whose rendered field resolves to a CustomField
# (OpenProject::JournalFormatter::CustomComment and the
# OpenProject::JournalFormatter::CustomField::* formatters). Requires the
# including class to implement +custom_field_for_key(key)+.
module OpenProject::JournalFormatter::CustomFieldPermission
  private

  # A Proc :view_permission is instance_exec'd with the CustomField being
  # rendered (or nil, if it has since been deleted) as its sole argument,
  # rather than with no arguments as JournalFormatter::Base does.
  def permission_granted?(options)
    permission = options[:view_permission]
    return super unless permission.is_a?(Proc)

    instance_exec(custom_field_for_key(options[:key]), &permission)
  end
end
