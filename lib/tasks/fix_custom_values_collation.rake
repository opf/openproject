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
  namespace :journals do
    desc "Fixes 'custom_values' table collation"
    task :fix_custom_values_collation => :environment do |task|
      ActiveRecord::Base.connection.execute <<-SQL
        ALTER TABLE custom_values CONVERT TO character SET utf8 COLLATE utf8_unicode_ci;
      SQL
    end
  end
end
