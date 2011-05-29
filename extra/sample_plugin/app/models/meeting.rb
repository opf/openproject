#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

class Meeting < ActiveRecord::Base
  belongs_to :project

  acts_as_journalized :event_title => Proc.new {|o| "#{o.scheduled_on} Meeting"},
                :event_datetime => :scheduled_on,
                :event_author => nil,
                :event_url => Proc.new {|o| {:controller => 'meetings', :action => 'show', :id => o.id}}
                :activity_timestamp => 'scheduled_on'
end
