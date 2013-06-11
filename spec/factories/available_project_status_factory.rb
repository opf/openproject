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

FactoryGirl.define do
  factory(:available_project_status, :class => AvailableProjectStatus) do |d|
    reported_project_status { |e| e.association :reported_project_status }
    project_type            { |e| e.association :project_type }
  end
end
