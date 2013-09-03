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

class ::Query::Results

  include Sums

  attr_accessor :options,
                :query

  # Valid options are :order, :include, :conditions
  def initialize(query, options = {})
    self.options = options
    self.query = query
  end

  # Returns the work package count
  def work_package_count
    WorkPackage.count(:include => [:status, :project], :conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  # Returns the work package count by group or nil if query is not grouped
  def work_package_count_by_group
    @work_package_count_by_group ||= begin
      r = nil
      if query.grouped?
        begin
          # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
          r = WorkPackage.count(:group => query.group_by_statement,
                                :include => [:status, :project],
                                :conditions => query.statement)
        rescue ActiveRecord::RecordNotFound
          r = {nil => work_package_count}
        end
        c = query.group_by_column
        if c.is_a?(QueryCustomFieldColumn)
          r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
        end
      end
      r
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def work_package_count_for(group)
    work_package_count_by_group[group]
  end

  def work_packages
    order_option = [query.group_by_sort_order, options[:order]].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    WorkPackage.where(::Query.merge_conditions(query.statement, options[:conditions]))
               .includes([:status, :project] + (options[:include] || []).uniq)
               .order(order_option)
  end

  def versions
    Version.find :all, :include => :project,
                       :conditions => ::Query.merge_conditions(query.project_statement, options[:conditions])
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end
end
