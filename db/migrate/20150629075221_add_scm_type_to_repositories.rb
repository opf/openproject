#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Adds the scm_type column to the repositories table and updates all previous
# repository to correspond to these types.
#
# As until now, OP only supported local Git repositories and local or remote Subversion
# repositories.
# We thus add the following types:
#
# - Repository::*: existing
# - Repository::Git: local
#
class AddScmTypeToRepositories < ActiveRecord::Migration[4.2]
  def up
    add_column :repositories, :scm_type, :string, null: true

    Repository.update_all(scm_type: 'existing')
    Repository.where(type: 'Repository::Git').update_all(scm_type: 'local')

    change_column_null :repositories, :scm_type, false
  end

  def down
    remove_column :repositories, :scm_type
  end
end
