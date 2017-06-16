#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class WorkPackage::Exporter::Base
  attr_accessor :object,
                :options

  def initialize(object, options = {})
    self.object = object
    self.options = options
  end

  def self.list(query, options = {})
    new(query, options).list
  end

  def self.single(work_package, options = {})
    new(work_package, options).single
  end

  def page
    options[:page] || 1
  end

  def valid_export_columns
    query.columns.select do |c|
      c.is_a?(Queries::WorkPackages::Columns::PropertyColumn) ||
        c.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn)
    end
  end

  alias :query :object
  alias :work_package :object

  def work_packages
    @work_packages ||= query
                       .results
                       .sorted_work_packages
                       .page(page)
                       .per_page(Setting.work_packages_export_limit.to_i)
  end
end
