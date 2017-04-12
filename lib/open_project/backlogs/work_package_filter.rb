#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

require 'story'
require 'task'

module OpenProject::Backlogs
  class WorkPackageFilter < ::Queries::Filters::Base

    alias :project :context
    alias :project= :context=

    def allowed_values
      [[I18n.t(:story, scope: [:backlogs]), 'story'],
       [I18n.t(:task, scope: [:backlogs]), 'task'],
       [I18n.t(:impediment, scope: [:backlogs]), 'impediment'],
       [I18n.t(:any, scope: [:backlogs]), 'any']]
    end

    def available?
      backlogs_enabled? &&
        backlogs_configured?
    end

    def self.key
      :backlogs_work_package_type
    end

    def self.sql_for_field(values, db_table, _db_field)
      sql = []

      selected_values = ['story', 'task'] if values.include?('any')

      story_types = Story.types.map(&:to_s).join(',')
      all_types = (Story.types + [Task.type]).map(&:to_s).join(',')

      selected_values.each do |val|
        case val
        when 'story'
          sql << "(#{db_table}.type_id IN (#{story_types}))"
        when 'task'
          sql << "(#{db_table}.type_id = #{Task.type} AND NOT #{db_table}.parent_id IS NULL)"
        when 'impediment'
          sql << "(#{db_table}.id IN (
                select from_id
                FROM relations ir
                JOIN work_packages blocked
                ON
                  blocked.id = ir.to_id
                  AND blocked.type_id IN (#{all_types})
                WHERE ir.relation_type = 'blocks'
              ) AND #{db_table}.parent_id IS NULL)"
        end

        case operator
        when '='
          sql = sql.join(' OR ')
        when '!'
          sql = 'NOT (' + sql.join(' OR ') + ')'
        end
      end

      sql
    end

    def order
      20
    end

    def type
      :list
    end

    def human_name
      WorkPackage.human_attribute_name(:backlogs_work_package_type)
    end

    def dependency_class
      '::API::V3::Queries::Schemas::BacklogsTypeDependencyRepresenter'
    end

    private

    def backlogs_configured?
      Story.types.present? && Task.type.present?
    end

    def backlogs_enabled?
      project.nil? || project.module_enabled?(:backlogs)
    end
  end
end
