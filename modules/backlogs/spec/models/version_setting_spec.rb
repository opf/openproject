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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VersionSetting, type: :model do
  let(:version_setting) { FactoryBot.build(:version_setting) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:version) }
  it { expect(VersionSetting.column_names).to include('display') }

  describe 'Instance Methods' do
    describe 'WITH display set to left' do
      before(:each) do
        version_setting.display_left!
      end

      it { expect(version_setting.display_left?).to be_truthy }
    end

    describe 'WITH display set to right' do
      before(:each) do
        version_setting.display_right!
      end

      it { expect(version_setting.display_right?).to be_truthy }
    end

    describe 'WITH display set to none' do
      before(:each) do
        version_setting.display_none!
      end

      it { expect(version_setting.display_none?).to be_truthy }
    end
  end
end
