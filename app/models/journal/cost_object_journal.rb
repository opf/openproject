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

class Journal::CostObjectJournal < ActiveRecord::Base

  # include ActiveModel::ForbiddenAttributesProtection

  self.table_name = "cost_object_journals"

  belongs_to :journal

  # attr_accessible :project_id, :author_id, :subject, :description, :fixed_date, :created_on


  @@journaled_attributes = [:project_id,
                            :author_id,
                            :subject,
                            :description,
                            :fixed_date]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end
end
