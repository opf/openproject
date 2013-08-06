#-- encoding: UTF-8
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

require File.expand_path('../shared/become_member', __FILE__)

module PermissionSpecs
  def self.included(base)
    base.class_eval do
      let(:project) { FactoryGirl.create(:project, :is_public => false) }
      let(:current_user) { FactoryGirl.create(:user) }

      include BecomeMember

      def self.check_permission_required_for(controller_action, permission)
        controller_name, action_name = controller_action.split('#')

        it "should allow calling #{controller_action} when having the permission #{permission} permission" do
          become_member_with_permissions(project, current_user, permission)

          controller.send(:authorize, controller_name, action_name).should be_true
        end

        it "should prevent calling #{controller_action} when not having the permission #{permission} permission" do
          become_member_with_permissions(project, current_user)

          controller.send(:authorize, controller_name, action_name).should be_false
        end
      end

      before do
        # As failures generate a response we need to prevent calls to nil
        controller.response = ActionController::TestResponse.new

        User.stub(:current).and_return(current_user)

        controller.instance_variable_set(:@project, project)
      end
    end
  end
end

