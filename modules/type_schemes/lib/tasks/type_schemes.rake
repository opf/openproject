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

namespace :type_schemes do
  desc "Create a Default Scheme from enabled types. MODE is dry_run (default), auto (create and assign) or manual (create only)"
  task :migrate, [:mode] => :environment do |_task, args|
    mode = args[:mode].presence || "dry_run"
    plan = TypeSchemes::DefaultMigration.call(mode:)

    puts "Mode: #{mode}"
    puts "Scheme: #{plan.scheme_name}"
    puts "Types: #{plan.type_names.join(', ').presence || '-'} (default: #{plan.default_type_name || '-'})"
    puts "Projects to assign (#{plan.project_names.size}): #{plan.project_names.join(', ').presence || '-'}"
    puts "No work package is changed; schemes only filter the types offered for new work packages."
  end
end
