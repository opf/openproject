#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal::MeetingJournal < ActiveRecord::Base
  self.table_name = "meeting_journals"

  belongs_to :journal
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  @@journaled_attributes = [:title,
                            :author_id,
                            :project_id,
                            :location,
                            :start_time,
                            :duration]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end

end
