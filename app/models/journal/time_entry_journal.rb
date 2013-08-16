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

class Journal::TimeEntryJournal < ActiveRecord::Base
  self.table_name = "time_entry_journals"

  belongs_to :journal

  @@journaled_attributes = [:project_id,
                            :user_id,
                            :work_package_id,
                            :hours,
                            :comments,
                            :activity_id,
                            :spent_on,
                            :tyear,
                            :tmonth,
                            :tweek]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end

end
