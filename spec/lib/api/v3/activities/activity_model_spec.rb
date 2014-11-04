#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Activities::ActivityModel do
  include Capybara::RSpecMatchers

  subject(:model) { ::API::V3::Activities::ActivityModel.new(journal) }
  let(:journal) { FactoryGirl.build(:work_package_journal, attributes) }

  context 'with a formatted description' do
    let(:attributes) {
      {
        notes: <<-DESC
h3. Plan update

# More done
# More quickly
       DESC
      }
    }

    describe '#notes' do
      subject { super().notes }
      it { is_expected.to have_selector 'h3' }
    end

    describe '#notes' do
      subject { super().notes }
      it { is_expected.to have_selector 'ol > li' }
    end

    describe '#raw_notes' do
      subject { super().raw_notes }
      it { is_expected.to eq attributes[:notes] }
    end

    it 'should allow raw_notes to be set' do
      model.raw_notes = 'h4. Plan revision'
      expect(model.notes).to have_selector 'h4'
    end
  end
end
