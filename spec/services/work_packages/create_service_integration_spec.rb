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
#++

require 'spec_helper'

describe WorkPackages::CreateService, 'integration', type: :model do
  let(:user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:role) do
    FactoryGirl.create(:role,
                       permissions: permissions)
  end

  let(:permissions) do
    %i(view_work_packages add_work_packages manage_subtasks)
  end

  let(:type) do
    FactoryGirl.create(:type,
                       custom_fields: [custom_field])
  end
  let(:default_type) do
    FactoryGirl.create(:type_standard)
  end
  let(:project) { FactoryGirl.create(:project, types: [type, default_type]) }
  let(:parent) do
    FactoryGirl.create(:work_package,
                       project: project,
                       type: type)
  end
  let(:instance) { described_class.new(user: user) }
  let(:custom_field) { FactoryGirl.create(:work_package_custom_field) }
  let(:other_status) { FactoryGirl.create(:status) }
  let(:default_status) { FactoryGirl.create(:default_status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:default_priority) { FactoryGirl.create(:default_priority) }
  let(:attributes) { {} }
  let(:new_work_package) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(attributes: attributes)
  end

  before do
    other_status
    default_status
    priority
    default_priority
    type
    default_type
    login_as(user)
  end

  describe '#call' do
    let(:attributes) do
      { subject: 'blubs',
        project: project,
        done_ratio: 50,
        parent: parent,
        start_date: Date.today,
        due_date: Date.today + 3.days }
    end

    it 'creates the work_package with the provided attributes' do
      # successful
      expect(service_result)
        .to be_success

      # attributes set as desired
      attributes.each do |key, value|
        expect(new_work_package.send(key))
          .to eql value
      end

      # service user as author
      expect(new_work_package.author)
        .to eql(user)

      # assign the default status
      expect(new_work_package.status)
        .to eql(default_status)

      # assign the default type
      expect(new_work_package.type)
        .to eql(default_type)

      # assign the default priority
      expect(new_work_package.priority)
        .to eql(default_priority)

      # parent updated
      parent.reload
      expect(parent.done_ratio)
        .to eql attributes[:done_ratio]
      expect(parent.start_date)
        .to eql attributes[:start_date]
      expect(parent.due_date)
        .to eql attributes[:due_date]
    end
  end
end
