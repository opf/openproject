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
  let(:admin) { FactoryGirl.build(:admin) }

  describe :permit do
    it "adds an attribute to be permitted later" do
      # just taking project_type here as an example, could be anything

      # taking the originally whitelisted params to be restored later
      original_whitelisted = PermittedParams.instance_variable_get(:@whitelisted_params)


      params = ActionController::Parameters.new(:project_type => { "blubs1" => "blubs" } )

      PermittedParams.new(params, user).project_type.should == {}

      PermittedParams.permit(:project_type, :blubs1)

      PermittedParams.new(params, user).project_type.should == { "blubs1" => "blubs" }


      PermittedParams.instance_variable_set(:@whitelisted_params, original_whitelisted)
    end

    it "raises an argument error if key does not exist" do
      expect{ PermittedParams.permit(:bogus_key) }.to raise_error ArgumentError
    end
  end

  describe :project_type do
    it "should return name" do
      params = ActionController::Parameters.new(:project_type => { "name" => "blubs" } )

      PermittedParams.new(params, user).project_type.should == { "name" => "blubs" }
    end

    it "should return allows_association" do
      params = ActionController::Parameters.new(:project_type => { "allows_association" => "1" } )

      PermittedParams.new(params, user).project_type.should == { "allows_association" => "1" }
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

    it "should permit due_date" do
      hash = { "due_date" => "2012-12-12" }

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

  describe :new_work_package do
    it "should permit subject" do
      hash = { "subject" => "blubs" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit description" do
      hash = { "description" => "blubs" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit start_date" do
      hash = { "start_date" => "2013-07-08" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit due_date" do
      hash = { "due_date" => "2013-07-08" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit assigned_to_id" do
      hash = { "assigned_to_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit responsible_id" do
      hash = { "responsible_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit type_id" do
      hash = { "type_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit planning_element_type_id" do
      hash = { "planning_element_type_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit prioritiy_id" do
      hash = { "priority_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit parent_id" do
      hash = { "parent_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit parent_id" do
      hash = { "parent_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit fixed_version_id" do
      hash = { "fixed_version_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit estimated_hours" do
      hash = { "estimated_hours" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit done_ratio" do
      hash = { "done_ratio" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit status_id" do
      hash = { "status_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit category_id" do
      hash = { "category_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should permit watcher_user_ids when the user is allowed to add watchers" do
      project = double('project')

      user.stub!(:allowed_to?).with(:add_work_package_watchers, project).and_return(true)

      hash = { "watcher_user_ids" => ["1", "2"] }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package(:project => project).should == hash
    end

    it "should not return watcher_user_ids when the user is not allowed to add watchers" do
      project = double('project')

      user.stub!(:allowed_to?).with(:add_work_package_watchers, project).and_return(false)

      hash = { "watcher_user_ids" => ["1", "2"] }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package(:project => project).should == {}
    end

    it "should permit custom field values" do
      hash = { "custom_field_values" => { "1" => "5" } }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
      hash = { "custom_field_values" => { "blubs" => "5", "5" => {"1" => "2"} } }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == {}
    end
  end

  describe :update_work_package do
    it "should permit subject" do
      hash = { "subject" => "blubs" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit description" do
      hash = { "description" => "blubs" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit start_date" do
      hash = { "start_date" => "2013-07-08" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit due_date" do
      hash = { "due_date" => "2013-07-08" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit assigned_to_id" do
      hash = { "assigned_to_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit responsible_id" do
      hash = { "responsible_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit type_id" do
      hash = { "type_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit planning_element_type_id" do
      hash = { "planning_element_type_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit prioritiy_id" do
      hash = { "priority_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit parent_id" do
      hash = { "parent_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit parent_id" do
      hash = { "parent_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit fixed_version_id" do
      hash = { "fixed_version_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit estimated_hours" do
      hash = { "estimated_hours" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit done_ratio" do
      hash = { "done_ratio" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit status_id" do
      hash = { "status_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit category_id" do
      hash = { "category_id" => "1" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit notes" do
      hash = { "notes" => "blubs" }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit attachments" do
      hash = { "attachments" => [{ "file" => "djskfj", "description" => "desc" }] }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package.should == hash
    end

    it "should permit time_entry if the user has the log_time permission" do
      hash = { "time_entry" => { "hours" => "5", "activity_id" => "1", "comments" => "lorem" } }

      project = double('project')
      user.stub(:allowed_to?).with(:log_time, project).and_return(true)

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package(:project => project).should == hash
    end

    it "should not permit time_entry if the user lacks the log_time permission" do
      hash = { "time_entry" => { "hours" => "5", "activity_id" => "1", "comments" => "lorem" } }

      project = double('project')
      user.stub(:allowed_to?).with(:log_time, project).and_return(false)

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).update_work_package(:project => project).should == {}
    end

    it "should permit custom field values" do
      hash = { "custom_field_values" => { "1" => "5" } }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == hash
    end

    it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
      hash = { "custom_field_values" => { "blubs" => "5", "5" => {"1" => "2"} } }

      params = ActionController::Parameters.new(:work_package => hash)

      PermittedParams.new(params, user).new_work_package.should == {}
    end
  end

  describe :user do
    admin_permissions = ['firstname',
                         'lastname',
                         'mail',
                         'mail_notification',
                         'language',
                         'custom_fields',
                         'identity_url',
                         'auth_source_id',
                         'force_password_change']

    it 'should permit nothing for a non-admin user' do
      # Hash with {'key' => 'key'} for all admin_permissions
      field_sample = { :user => Hash[admin_permissions.zip(admin_permissions)] }

      params = ActionController::Parameters.new(field_sample)
      PermittedParams.new(params, user).user_update_as_admin.should == {}
    end

    admin_permissions.each do |field|
      it "should permit #{field}" do
        hash = { field => 'test' }
        params = ActionController::Parameters.new(:user => hash)

        PermittedParams.new(params, admin).user_update_as_admin.should ==
          { field => 'test' }
      end
    end

    it 'should permit a group_ids list' do
      hash = { 'group_ids' => ['1', '2'] }
      params = ActionController::Parameters.new(:user => hash)

      PermittedParams.new(params, admin).user_update_as_admin.should == hash
    end

    it "should permit custom field values" do
      hash = { "custom_field_values" => { "1" => "5" } }

      params = ActionController::Parameters.new(:user => hash)

      PermittedParams.new(params, admin).user_update_as_admin.should == hash
    end

    it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
      hash = { "custom_field_values" => { "blubs" => "5", "5" => {"1" => "2"} } }

      params = ActionController::Parameters.new(:user => hash)

      PermittedParams.new(params, admin).user_update_as_admin.should == {}
    end
  end
end
