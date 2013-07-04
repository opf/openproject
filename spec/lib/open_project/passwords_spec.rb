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
require 'open_project/passwords'

describe OpenProject::Passwords::Generator do
  describe :random_password do
    it "should create a valid password" do
      with_settings :password_active_rules => ['lowercase', 'uppercase', 'numeric', 'special'],
                    :password_min_adhered_rules => 3,
                    :password_min_length => 4 do
       pwd = OpenProject::Passwords::Generator.random_password
       OpenProject::Passwords::Evaluator.conforming?(pwd).should == true
     end
   end
  end
end

describe OpenProject::Passwords::Evaluator do
  it "should correctly evaluate passwords" do
    with_settings :password_active_rules => ['lowercase', 'uppercase', 'numeric'],
                  :password_min_adhered_rules => 3,
                  :password_min_length => 4 do
      OpenProject::Passwords::Evaluator.conforming?('abCD').should == false
      OpenProject::Passwords::Evaluator.conforming?('ab12').should == false
      OpenProject::Passwords::Evaluator.conforming?('12CD').should == false
      OpenProject::Passwords::Evaluator.conforming?('12CD*').should == false
      OpenProject::Passwords::Evaluator.conforming?('aB1').should == false
      OpenProject::Passwords::Evaluator.conforming?('abCD12').should == true
      OpenProject::Passwords::Evaluator.conforming?('aB123').should == true
    end
  end
end
