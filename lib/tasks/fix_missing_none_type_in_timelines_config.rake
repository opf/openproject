#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative '../../db/migrate/migration_utils/utils'

namespace :migrations do
  namespace :timelines do
    desc "Fixes missing 'none' type in timelines configuration"
    task :fix_missing_none_type_in_timelines_config => :environment do |task|
      standard_type = Type.find_by_is_standard(true)

      if standard_type.nil?
        raise "No standard type exists! You have to run the production seed "\
              "beforehand."
      end

      migrator_class = create_migrator_class

      timelines_migrator = migrator_class.new(standard_type)

      timelines_migrator.migrate
    end

    private

    PE_TYPE_KEY = 'planning_element_types'

    # We create the migration class dynamically because rake would try to
    # execute the migration on 'rake db:migrate' otherwise.
    #
    # We inherit from 'ActiveRecord::Migration' to reuse code already
    # written for the migrations.
    def create_migrator_class
      Class.new(ActiveRecord::Migration) do
        include Migration::Utils

        def initialize(standard_type)
          @standard_type = standard_type
        end

        def migrate
          say_with_time_silently "Set 'none' type id in timelines options" do
            update_column_values('timelines',
                                 ['options'],
                                 update_options(add_none_type_id),
                                nil)
          end
        end

        def add_none_type_id
          Proc.new do |timelines_opts|
            add_none_type_id_to_options timelines_opts
          end
        end

        def add_none_type_id_to_options(options)
          pe_types = []
          pe_types = options[PE_TYPE_KEY] if options.has_key? PE_TYPE_KEY

          pe_types.map! { |t| (t == 0) ? @standard_type.id : t }

          options[PE_TYPE_KEY] = pe_types

          options
        end
      end
    end
  end
end
