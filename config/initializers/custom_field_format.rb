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

OpenProject::CustomFieldFormat.map do |fields|
  fields.register OpenProject::CustomFieldFormat.new("string",
                                                     label: :label_string,
                                                     order: 1)
  fields.register OpenProject::CustomFieldFormat.new("text",
                                                     label: :label_text,
                                                     order: 2,
                                                     formatter: "CustomValue::FormattableStrategy")
  fields.register OpenProject::CustomFieldFormat.new("link",
                                                     label: :label_link_url,
                                                     only: %w(WorkPackage Project),
                                                     order: 3,
                                                     formatter: "CustomValue::LinkStrategy")
  fields.register OpenProject::CustomFieldFormat.new("int",
                                                     label: :label_integer,
                                                     order: 4,
                                                     formatter: "CustomValue::IntStrategy")
  fields.register OpenProject::CustomFieldFormat.new("float",
                                                     label: :label_float,
                                                     order: 5,
                                                     formatter: "CustomValue::FloatStrategy")
  fields.register OpenProject::CustomFieldFormat.new("list",
                                                     label: :label_list,
                                                     order: 6,
                                                     formatter: "CustomValue::ListStrategy")
  fields.register OpenProject::CustomFieldFormat.new("date",
                                                     label: :label_date,
                                                     order: 7,
                                                     formatter: "CustomValue::DateStrategy")
  fields.register OpenProject::CustomFieldFormat.new("bool",
                                                     label: :label_boolean,
                                                     order: 8,
                                                     formatter: "CustomValue::BoolStrategy")
  fields.register OpenProject::CustomFieldFormat.new("user",
                                                     label: Proc.new { User.model_name.human },
                                                     only: %w(WorkPackage TimeEntry
                                                              Version Project),
                                                     edit_as: "list",
                                                     order: 9,
                                                     formatter: "CustomValue::UserStrategy")
  fields.register OpenProject::CustomFieldFormat.new("version",
                                                     label: Proc.new { Version.model_name.human },
                                                     only: %w(WorkPackage TimeEntry
                                                              Version Project),
                                                     edit_as: "list",
                                                     order: 10,
                                                     formatter: "CustomValue::VersionStrategy")
  # This is an internal formatter used as a fallback in case a value is not found.
  # Setting the label to nil in order to avoid it becoming available for selection as a custom value format.
  fields.register OpenProject::CustomFieldFormat.new("empty",
                                                     label: nil,
                                                     order: 11,
                                                     formatter: "CustomValue::EmptyStrategy")
end
