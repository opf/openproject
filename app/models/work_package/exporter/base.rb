#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class WorkPackage::Exporter::Base
  attr_accessor :object,
                :options

  def initialize(object, options = {})
    self.object = object
    self.options = options
  end

  def self.list(query, options = {}, &block)
    new(query, options).list(&block)
  end

  def self.single(work_package, options = {}, &block)
    new(work_package, options).single(&block)
  end

  # Provide means to clean up after the export
  def cleanup; end

  def page
    options[:page] || 1
  end

  def valid_export_columns
    query.columns.reject do |c|
      c.is_a?(Queries::WorkPackages::Columns::RelationColumn)
    end
  end

  alias :query :object
  alias :work_package :object

  # Remove characters that could cause problems on popular OSses
  def sane_filename(name)
    parts = name.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    parts.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    parts.join '.'
  end

  def work_packages
    @work_packages ||= query
                       .results
                       .sorted_work_packages
                       .page(page)
                       .per_page(Setting.work_packages_export_limit.to_i)
  end
end
