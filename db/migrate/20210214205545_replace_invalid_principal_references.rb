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

class ReplaceInvalidPrincipalReferences < ActiveRecord::Migration[6.1]
  def up
    DeletedUser.reset_column_information
    deleted_user_id = DeletedUser.first.id

    say "Replacing invalid custom value user references"
    CustomValue
      .joins(:custom_field)
      .where("#{CustomField.table_name}.field_format" => "user")
      .where("value NOT IN (SELECT id::text FROM users)")
      .update_all(value: deleted_user_id)

    say "Replacing invalid responsible user references in work packages"
    WorkPackage
      .where("responsible_id NOT IN (SELECT id FROM users)")
      .update_all(responsible_id: deleted_user_id)
  end

  def down
    # Nothing to do, as only invalid data is fixed
  end
end
