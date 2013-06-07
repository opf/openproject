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

module Notifier
  def self.notify?(event)
    notified_events.include?(event.to_s)
  end
  
  def self.notified_events
    Setting.notified_events.to_a
  end
end
