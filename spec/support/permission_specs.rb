#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../shared/become_member', __FILE__)

module PermissionSpecs
  def self.included(base)
    base.class_eval do
      let(:project) { FactoryBot.create(:project, public: false) }
      let(:current_user) { FactoryBot.create(:user) }

      include BecomeMember

      def self.check_permission_required_for(controller_action, permission)
        controller_name, action_name = controller_action.split('#')

        it "should allow calling #{controller_action} when having the permission #{permission} permission" do
          become_member_with_permissions(project, current_user, permission)

          expect(controller.send(:authorize, controller_name, action_name)).to be_truthy
        end

        it "should prevent calling #{controller_action} when not having the permission #{permission} permission" do
          become_member_with_permissions(project, current_user)

          expect(controller.send(:authorize, controller_name, action_name)).to be_falsey
        end
      end

      before do
        # As failures generate a response we need to prevent calls to nil
        controller.response = ActionDispatch::TestResponse.new

        allow(User).to receive(:current).and_return(current_user)

        controller.instance_variable_set(:@project, project)
      end
    end
  end
end
