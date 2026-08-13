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
# (OpenProject::JournalFormatter::CustomComment and
# OpenProject::JournalFormatter::CustomField). Requires the including class to
# implement +custom_field_for_key(key)+ and +project+.
#
# Self-contained (does not rely on a JournalFormatter::Base ancestor via
# +super+) so it can be mixed into formatters that aren't Base subclasses,
# such as CustomField, which is a plain dispatcher and has no other use for
# Base's rendering machinery.
module OpenProject::JournalFormatter::CustomField::ViewPermission
  # A Proc permission is instance_exec'd with the CustomField being
  # rendered (or nil, if it has since been deleted) as its sole argument,
  # rather than with no arguments as JournalFormatter::Base does.
  def permission_granted?(permission, key: nil)
    return true unless permission

    if permission.is_a?(Proc)
      instance_exec(custom_field_for_key(key), &permission)
    else
      User.current.allowed_in_project?(permission, project)
    end
  end

  private

  # The (user, project) visibility check queries the DB every time it runs; activity feeds
  # render many custom-field journal entries per request, often for the same project, so we
  # cache the verdict set per request and per user. Only used by view_permission Procs
  # (see WorkPackage::Journalized), which #permission_granted? instance_exec's above.
  def visible_custom_field_ids(project)
    JournalFormatterCache.fetch(WorkPackageCustomField, project.id) do # rubocop:disable Lint/UselessDefaultValueArgument
      WorkPackageCustomField.visible(User.current, project:).pluck(:id).to_set
    end
  end
end
