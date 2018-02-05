#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++require 'rspec'

require 'spec_helper'

describe ::API::V3::WorkPackages::CustomActions::CustomActionsWrapper do
  let(:work_package) { FactoryGirl.build_stubbed(:stubbed_work_package) }
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:custom_action) { FactoryGirl.build_stubbed(:custom_action) }

  let(:instance) do
    described_class.send(:new, work_package, [custom_action])
  end

  describe '.new' do
    it 'raises a private method called error' do
      expect{ described_class.new(work_package, user) }
        .to raise_error(NoMethodError)
    end
  end

  describe '#custom_actions' do
    it 'returns the preloaded actions' do
      expect(instance.custom_actions(user))
        .to match_array [custom_action]
    end
  end

  %i(id subject description status_id comment author_id assigned_to_id).each do |attribute|
    describe "#{attribute}" do
      it 'delegates to work_package' do
        expect(work_package)
          .to receive(attribute)
          .and_return(123)

        expect(instance.send(attribute))
          .to eql 123
      end
    end
  end
end
