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

class QueryColumn
  attr_accessor :name,
                :sortable,
                :groupable,
                :summable,
                :available,
                :join,
                :default_order
  alias_method :summable?, :summable
  include Redmine::I18n

  def initialize(name, options = {})
    self.name = name

    %i(sortable
       groupable
       summable
       default_order).each do |attribute|
      send("#{attribute}=", options[attribute])
    end

    self.available = options.fetch(:available, true)

    self.join = options.delete(:join)

    @caption_key = options[:caption] || name.to_s
  end

  def caption
    WorkPackage.human_attribute_name(@caption_key)
  end

  def groupable=(value)
    @groupable = name_or_value_or_false(value)
  end

  def sortable=(value)
    @sortable =  name_or_value_or_false(value)
  end

  # Returns true if the column is sortable, otherwise false
  def sortable?
    !!sortable
  end

  # Returns true if the column is groupable, otherwise false
  def groupable?
    !!groupable
  end

  def value(issue)
    issue.send name
  end

  def available?
    available
  end

  def available
    if name == :done_ratio
      !WorkPackage.done_ratio_disabled?
    else
      @available
    end
  end

  def sum_of(work_packages)
    if work_packages.is_a?(Array)
      # TODO: Sums::grouped_sums might call through here without an AR::Relation
      # Ensure that this also calls using a Relation and drop this (slow!) implementation
      work_packages.map { |wp| value(wp) }.compact.reduce(:+)
    else
      work_packages.sum(name)
    end
  end

  protected

  def name_or_value_or_false(value)
    # This is different from specifying value = nil in the signature
    # in that it will also set the value to false if nil is provided.
    value ||= false

    # Explicitly checking for true because apparently, we do not want
    # truish values to count here.
    if (value == true)
      name.to_s
    else
      value
    end
  end
end
