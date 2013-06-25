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

class ReportedProjectStatus < Enumeration

  extend Pagination::Model

  unloadable

  scope :like, lambda { |q|
    s = "%#{q.to_s.strip.downcase}%"
    { :conditions => ["LOWER(name) LIKE :s", {:s => s}],
    :order => "name" }
  }

  has_many :reportings, :class_name  => "Reporting",
                        :foreign_key => 'reported_project_status_id'

  OptionName = :enumeration_reported_project_statuses

  def option_name
    OptionName
  end

  def objects_count
    reportings.count
  end

  def transfer_relations(to)
    reportings.update.all(:reported_project_status_id => to.id)
  end

  def self.search_scope(query)
    like(query)
  end
end
