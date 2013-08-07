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

require 'spec_helper'

describe TimelogController do
  it "should connect GET /work_packages/:work_package_id/time_entries/new to timelog#new" do
    get("/work_packages/1/time_entries/new").should route_to( :controller => 'timelog',
                                                              :action => 'new',
                                                              :work_package_id => '1' )
  end
end
