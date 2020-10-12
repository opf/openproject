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

require 'spec_helper'

describe WorkPackages::CreateService, 'integration', type: :model do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end

  let(:permissions) do
    %i(view_work_packages add_work_packages manage_subtasks)
  end

  let(:type) do
    FactoryBot.create(:type,
                      custom_fields: [custom_field])
  end
  let(:default_type) do
    FactoryBot.create(:type_standard)
  end
  let(:project) { FactoryBot.create(:project, types: [type, default_type]) }
  let(:parent) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: type)
  end
  let(:instance) { described_class.new(user: user) }
  let(:custom_field) { FactoryBot.create(:work_package_custom_field) }
  let(:other_status) { FactoryBot.create(:status) }
  let(:default_status) { FactoryBot.create(:default_status) }
  let(:priority) { FactoryBot.create(:priority) }
  let(:default_priority) { FactoryBot.create(:default_priority) }
  let(:attributes) { {} }
  let(:new_work_package) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(attributes)
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

    describe 'setting the attachments' do
      let!(:other_users_attachment) do
        FactoryBot.create(:attachment, container: nil, author: FactoryBot.create(:user))
      end
      let!(:users_attachment) do
        FactoryBot.create(:attachment, container: nil, author: user)
      end

      it 'reports on invalid attachments and sets the new if everything is valid' do
        result = instance.call(attributes.merge(attachment_ids: [other_users_attachment.id]))

        expect(result)
          .to be_failure

        expect(result.errors.symbols_for(:attachments))
          .to match_array [:does_not_exist]

        # The parent work package
        expect(WorkPackage.count)
          .to eql 1

        expect(other_users_attachment.reload.container)
          .to be_nil

        result = instance.call(attributes.merge(attachment_ids: [users_attachment.id]))

        expect(result)
          .to be_success

        expect(result.result.attachments)
          .to match_array [users_attachment]

        expect(users_attachment.reload.container)
          .to eql result.result
      end
    end
  end
end
