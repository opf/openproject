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

# `db:prepare` boots the application *before* it creates the database and loads
# the schema, which leaves this process holding two kinds of stale state by the
# time it gets here.
#
# When the database did not exist at all, the boot fell back to NullDB and never
# came back off it, so without this the seeders would write into the void.
OpenProject::NullDbFallback.reset

# And every model an engine touches from a `to_prepare` block looked up its
# columns while no table existed yet — memoising that empty answer for the rest
# of the process, which leaves the model without any attribute methods. Throw
# that away so the seeders work against the schema that has since been loaded.
ActiveRecord::Base.connection_pool.schema_cache.clear!
ActiveRecord::Base.descendants.each(&:reset_column_information)
Setting.clear_cache

Seeder.log_to_stdout!
RootSeeder.new(raise_on_unknown_language: true).seed!
