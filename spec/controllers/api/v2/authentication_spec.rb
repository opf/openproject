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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::AuthenticationController do
  describe 'index.xml' do
    def fetch
      get 'index', :format => 'xml'
    end

    it_should_behave_like "a controller action with require_login"
  end
end
