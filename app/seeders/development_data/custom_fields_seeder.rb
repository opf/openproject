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
module DevelopmentData
  class CustomFieldsSeeder < Seeder
    def seed_data!
      CustomField.transaction do
        print '    ↳ Creating custom fields...'
        cfs = create_cfs!

        print "\n    ↳ Creating types for linking CFs"
        create_types!(cfs)
      end

      puts
    end

    def all_cfs
      %w(string text date list multilist int intrange float user version)
    end

    def create_types!(cfs)
      # Create ALL CFs types
      non_req_cfs = cfs.reject(&:is_required).map { |cf| "custom_field_#{cf.id}" }
      type = FactoryBot.build :type_with_workflow, name: 'All CFS'
      extend_group(type, ['Custom fields', non_req_cfs])
      type.save!
      print '.'

      # Create type
      req_cfs = cfs.select(&:is_required).map { |cf| "custom_field_#{cf.id}" }
      type_req = FactoryBot.build :type_with_workflow, name: 'Required CF'
      extend_group(type_req, ['Custom fields', req_cfs])
      type_req.save!
      print '.'
    end

    def create_cfs!
      cfs = []

      # create some custom fields and add them to the project
      (all_cfs - %w(list multilist intrange)).each do |type|
        cfs << CustomField.create!(name: "CF DEV #{type}",
                                   type: 'WorkPackageCustomField',
                                   is_required: false,
                                   field_format: type)
        print '.'
      end

      cfs << CustomField.create!(name: "CF DEV list",
                                 is_required: false,
                                 type: 'WorkPackageCustomField',
                                 possible_values: ['A', 'B', 'C'],
                                 field_format: 'list')
      print '.'

      cfs << CustomField.create!(name: "CF DEV multilist",
                                 type: 'WorkPackageCustomField',
                                 is_required: false,
                                 multi_value: true,
                                 possible_values: ['Foo', 'Bar', 'Bla'],
                                 field_format: 'list')
      print '.'

      cfs << CustomField.create!(name: "CF DEV required text",
                                 type: 'WorkPackageCustomField',
                                 is_required: true,
                                 field_format: 'text')
      print '.'

      cfs << CustomField.create!(name: "CF DEV intrange",
                                 type: 'WorkPackageCustomField',
                                 min_length: 2,
                                 max_length: 5,
                                 field_format: 'int')
      print '.'

      cfs
    rescue => e
      binding.pry
    end

    def extend_group(type, group)
      groups = type.send(:custom_attribute_groups) || type.default_attribute_groups
      groups << group
      type.attribute_groups = groups
    end

    def applicable?
      CustomField.where("name LIKE 'CF DEV%'").count == 0
    end
  end
end
