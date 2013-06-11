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

require File.expand_path('../../spec_helper', __FILE__)

describe PermittedParams do
  let(:user) { FactoryGirl.build(:user) }

  describe :project_type do
    it "should return name" do
      params = ActionController::Parameters.new(:project_type => { "name" => "blubs" } )

      PermittedParams.new(params, user).project_type.should == { "name" => "blubs" }
    end

    it "should return allows_association" do
      params = ActionController::Parameters.new(:project_type => { "allows_association" => "1" } )

      PermittedParams.new(params, user).project_type.should == { "allows_association" => "1" }
    end

    it "should return planning_element_type_ids" do
      params = ActionController::Parameters.new(:project_type => { "planning_element_type_ids" => ["1"] } )

      PermittedParams.new(params, user).project_type.should == { "planning_element_type_ids" => ["1"] }
    end

    it "should return reported_project_status_ids" do
      params = ActionController::Parameters.new(:project_type => { "reported_project_status_ids" => ["1"] } )

      PermittedParams.new(params, user).project_type.should == { "reported_project_status_ids" => ["1"] }
    end
  end

  describe :project_type_move do
    it "should permit move_to" do
      params = ActionController::Parameters.new(:project_type => { "move_to" => "1" } )

      PermittedParams.new(params, user).project_type_move.should == { "move_to" => "1" }
    end
  end

  describe :color do
    it "should permit name" do
      params = ActionController::Parameters.new(:color => { "name" => "blubs" } )

      PermittedParams.new(params, user).color.should == { "name" => "blubs" }
    end

    it "should permit hexcode" do
      params = ActionController::Parameters.new(:color => { "hexcode" => "#fff" } )

      PermittedParams.new(params, user).color.should == { "hexcode" => "#fff" }
    end
  end

  describe :color_move do
    it "should permit move_to" do
      params = ActionController::Parameters.new(:color => { "move_to" => "1" } )

      PermittedParams.new(params, user).color_move.should == { "move_to" => "1" }
    end
  end

  describe :planning_element_type do
    it "should permit move_to" do
      hash = { "name" => "blubs" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type.should == hash
    end

    it "should permit in_aggregation" do
      hash = { "in_aggregation" => "1" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type.should == hash
    end

    it "should permit is_milestone" do
      hash = { "is_milestone" => "1" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type.should == hash
    end

    it "should permit is_default" do
      hash = { "is_default" => "1" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type.should == hash
    end

    it "should permit color_id" do
      hash = { "color_id" => "1" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type.should == hash
    end
  end

  describe :planning_element_type_move do
    it "should permit move_to" do
      hash = { "move_to" => "1" }

      params = ActionController::Parameters.new(:planning_element_type => hash)

      PermittedParams.new(params, user).planning_element_type_move.should == hash
    end
  end

  describe :scenario do
    it "should permit name" do
      hash = { "name" => "blubs" }

      params = ActionController::Parameters.new(:scenario => hash)

      PermittedParams.new(params, user).scenario.should == hash
    end

    it "should permit description" do
      hash = { "description" => "blubs" }

      params = ActionController::Parameters.new(:scenario => hash)

      PermittedParams.new(params, user).scenario.should == hash
    end
  end

  describe :planning_element do
    it "should permit planning_element" do
      hash = { "subject" => "blubs" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit description" do
      hash = { "description" => "blubs" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit start_date" do
      hash = { "start_date" => "2012-12-12" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit end_date" do
      hash = { "end_date" => "2012-12-12" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit scenarios" do
      hash = { "scenarios" => {'id' => "1", 'start_date' => '2012-01-01', 'end_date' => '2012-01-03' } }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit note" do
      hash = { "note" => "lorem" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit planning_element_type_id" do
      hash = { "planning_element_type_id" => "1" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit planning_element_status_comment" do
      hash = { "planning_element_status_comment" => "lorem" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit planning_element_status_id" do
      hash = { "planning_element_status_id" => "1" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit parent_id" do
      hash = { "parent_id" => "1" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end

    it "should permit responsible_id" do
      hash = { "responsible_id" => "1" }

      params = ActionController::Parameters.new(:planning_element => hash)

      PermittedParams.new(params, user).planning_element.should == hash
    end
  end
end
