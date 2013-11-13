# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'db_worker'
require 'syck'

module Migration
  module YamlMigrator
    include DbWorker

    def migrate_yaml(table, column, source_yamler, target_yamler)
      current_yamler = YAML::ENGINE.yamler
      fetch_data(table,column).each do | data |
        db_execute <<-SQL
          UPDATE #{quoted_table_name(table)}
          SET #{db_column(column)} = #{quote_value(yaml_to_yaml(data[column],source_yamler, target_yamler))}
          WHERE id = #{data['id']};
        SQL
      end
    ensure
      # psych is the default starting at ruby 1.9.3, so we explicitely set it here
      # in case no yamler was set to return to a sensible default
      YAML::ENGINE.yamler = current_yamler.present? ? current_yamler : 'psych'
    end

    def fetch_data(table, column)
      ActiveRecord::Base.connection.select_all <<-SQL
        SELECT #{db_column('id')}, #{db_column(column)}
        FROM #{quoted_table_name(table)}
        WHERE #{db_column(column)} LIKE #{quote_value('---%')}
      SQL
    end

    def yaml_to_yaml(data, source_yamler, target_yamler)
      YAML::ENGINE.yamler = source_yamler
      original = YAML.load(data)
      YAML::ENGINE.yamler = target_yamler
      YAML.dump original
    end
  end
end
