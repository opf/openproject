#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require_relative 'db_worker'
require 'syck'

module Migration
  module YamlMigrator
    include DbWorker

    def migrate_yaml(table, column, source_yamler, target_yamler)
      current_yamler = YAML::ENGINE.yamler
      fetch_data(table, column).each do | data |
        db_execute <<-SQL
          UPDATE #{quoted_table_name(table)}
          SET #{db_column(column)} = #{quote_value(yaml_to_yaml(data[column], source_yamler, target_yamler))}
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
