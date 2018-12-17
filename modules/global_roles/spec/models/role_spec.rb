#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Role, type: :model do
  describe 'class methods' do
    describe '#givable' do
      before do
        # this should not be necessary once Role (in a membership) and GlobalRole have
        # a common ancestor class, e.g. Role (a new one)
        @mem_role1 = Role.create name: 'mem_role', permissions: []
        @builtin_role1 = Role.new name: 'builtin_role1', permissions: []
        @builtin_role1.builtin = 3
        @builtin_role1.save
        @global_role1 = GlobalRole.create name: 'global_role1', permissions: []
      end

      it { expect(Role.find_all_givable.size).to eq(1) }
      it { expect(Role.find_all_givable[0]).to eql @mem_role1 }
    end
  end

  describe 'instance methods' do
    before do
      @role = Role.new
    end

    describe '#setable_permissions' do
      before { mock_permissions_for_setable_permissions }

      it { expect(@role.setable_permissions).to eql([@perm1, @perm2]) }
    end
  end
end
