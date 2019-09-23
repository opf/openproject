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

describe PrincipalRole, type: :model do
  describe 'ATTRIBUTES' do
    before :each do
    end

    it { is_expected.to belong_to :principal }
    it { is_expected.to belong_to :role }
  end

  describe '#valid?' do
    before(:each) do
      @principal_role = FactoryBot.build(:principal_role)
    end

    describe 'role not assignable to user' do
      before :each do
        allow(@principal_role.role).to receive(:assignable_to?).and_return(false)
      end

      it { expect(@principal_role.valid?).to be_falsey }
      it {
        @principal_role.valid?
        expect(@principal_role.errors[:base]).to include(I18n.t(:error_can_not_be_assigned))
      }
    end

    describe 'role assignable to user' do
      before(:each) do
        allow(@principal_role.role).to receive(:assignable_to?).and_return(true)
      end

      it { expect(@principal_role.valid?).to be_truthy }
    end
  end
end
