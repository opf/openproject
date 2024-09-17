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

class AddUniquenessContrainToBcfTopicOnUuid < ActiveRecord::Migration[6.0]
  def up
    # Create unique index on an issue's uuid. A BCF issue should only exist once on an instance. If you need a copy,
    # then it is not the same anymore and thus should have a different uuid.
    remove_index :bcf_issues, :uuid
    add_index :bcf_issues, %i[uuid], unique: true
  end

  def down
    remove_index :bcf_issues, :uuid
    add_index :bcf_issues, %i[uuid]
  end
end
