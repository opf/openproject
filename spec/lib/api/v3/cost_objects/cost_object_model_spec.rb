#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe ::API::V3::CostObjects::CostObjectModel do
  include Capybara::RSpecMatchers

  let(:project) { FactoryGirl.build(:project) }
  let(:user) { FactoryGirl.build(:user, member_in_project: project) }
  let(:cost_object) { FactoryGirl.build(:cost_object,
                                        author: user,
                                        project: project,
                                        updated_on: Date.today) }

  subject(:model) { ::API::V3::CostObjects::CostObjectModel.new(cost_object) }

  describe 'attributes' do
    it { expect(subject.project_id).to eq(cost_object.project_id) }

    it { expect(subject.author.id).to eq(cost_object.author_id) }

    it { expect(subject.subject).to eq(cost_object.subject) }

    it { expect(subject.description).to eq(cost_object.description) }

    it { expect(subject.type).to eq(cost_object.type) }

    it { expect(subject.fixed_date).to eq(cost_object.fixed_date) }

    it { expect(subject.created_on).to eq(cost_object.created_on) }

    it { expect(subject.updated_on).to eq(cost_object.updated_on) }
  end
end
