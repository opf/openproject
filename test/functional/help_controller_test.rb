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

require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test "renders wiki_syntax properly" do
    get "wiki_syntax"

    assert_select "h1", "Wiki Syntax Quick Reference"
  end

  test "renders wiki_syntax_detailed properly" do
    get "wiki_syntax_detailed"

    assert_select "h1", "Wiki Formatting"
  end
end
