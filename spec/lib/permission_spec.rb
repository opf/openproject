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

describe Redmine::AccessControl::Permission do
  describe 'WHEN setting global permission' do
    describe 'creating with', :new do
      before { @permission = Redmine::AccessControl::Permission.new(:perm, { cont: [:action] }, { global: true }) }
      describe '#global?' do
        it { expect(@permission.global?).to be_truthy }
      end
    end
  end

  describe 'setting non_global' do
    describe 'creating with', :new do
      before { @permission = Redmine::AccessControl::Permission.new :perm, { cont: [:action] }, { global: false } }

      describe '#global?' do
        it { expect(@permission.global?).to be_falsey }
      end
    end

    describe 'creating with', :new do
      before { @permission = Redmine::AccessControl::Permission.new :perm, { cont: [:action] }, {} }

      describe '#global?' do
        it { expect(@permission.global?).to be_falsey }
      end
    end
  end
end
