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
# frozen_string_literal: true

namespace :field_rules do
  desc "Remove rules of deleted custom fields and fix impossible rule states. MODE is dry_run (default) or apply"
  task :repair, [:mode] => :environment do |_task, args|
    mode = args[:mode].presence || "dry_run"
    abort "mode must be dry_run or apply" unless %w[dry_run apply].include?(mode)

    report = FieldRules::Repair.call(dry_run: mode == "dry_run")
    puts "Mode: #{mode}"
    puts "Rules of deleted custom fields: #{report.orphan_rules}"
    puts "Rules with impossible state: #{report.invalid_rules}"
    puts "No work package is changed."
  end
end
