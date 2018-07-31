#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
      let(:is_public) { false }
      let(:project) { FactoryBot.create(:project, is_public: is_public) }
      let(:current_user) { FactoryBot.create(:user) }

      include BecomeMember

      def self.check_permission_required_for(controller_action, permission, publishable_permission: false)
        controller_name, action_name = controller_action.split('#')

        it "should allow calling #{controller_action} when having the permission #{permission} permission" do
          become_member_with_permissions(project, current_user, permission)

          expect(controller.send(:authorize, controller_name, action_name)).to be_truthy
        end


        if publishable_permission
          context 'when user is non-member' do
            let!(:role) { FactoryBot.create :non_member }
            let(:is_public) { true }

            it 'authorizes on the public permission' do
              expect(controller.send(:authorize, controller_name, action_name)).to be_truthy
            end
          end
        else
          it "should prevent calling #{controller_action} when not having the permission #{permission} permission" do
            become_member_with_permissions(project, current_user)

            expect(controller.send(:authorize, controller_name, action_name)).to be_falsey
          end
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
