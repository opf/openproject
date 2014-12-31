#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

Redmine::CustomFieldFormat.map do |fields|
  fields.register Redmine::CustomFieldFormat.new('string',
                                                 label: :label_string,
                                                 order: 1)
  fields.register Redmine::CustomFieldFormat.new('text',
                                                 label: :label_text,
                                                 order: 2)
  fields.register Redmine::CustomFieldFormat.new('int',
                                                 label: :label_integer,
                                                 order: 3)
  fields.register Redmine::CustomFieldFormat.new('float',
                                                 label: :label_float,
                                                 order: 4)
  fields.register Redmine::CustomFieldFormat.new('list',
                                                 label: :label_list,
                                                 order: 5)
  fields.register Redmine::CustomFieldFormat.new('date',
                                                 label: :label_date,
                                                 order: 6)
  fields.register Redmine::CustomFieldFormat.new('bool',
                                                 label: :label_boolean,
                                                 order: 7)
  fields.register Redmine::CustomFieldFormat.new('user',
                                                 label: Proc.new { User.model_name.human },
                                                 only: %w(WorkPackage TimeEntry
                                                          Version Project),
                                                 edit_as: 'list',
                                                 order: 8)
  fields.register Redmine::CustomFieldFormat.new('version',
                                                 label: Proc.new { Version.model_name.human },
                                                 only: %w(WorkPackage TimeEntry
                                                          Version Project),
                                                 edit_as: 'list',
                                                 order: 9)
end
