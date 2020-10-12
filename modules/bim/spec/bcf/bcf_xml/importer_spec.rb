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

describe ::OpenProject::Bim::BcfXml::Importer do
  let(:filename) { 'MaximumInformation.bcf' }
  let(:file) do
    Rack::Test::UploadedFile.new(
      File.join(Rails.root, "modules/bim/spec/fixtures/files/#{filename}"),
      'application/octet-stream'
    )
  end
  let(:type) { FactoryBot.create :type, name: 'Issue', is_standard: true, is_default: true }
  let(:project) do
    FactoryBot.create(:project,
                      identifier: 'bim_project',
                      types: [type])
  end
  let(:member_role) do
    FactoryBot.create(:role,
                      permissions: %i[view_linked_issues view_work_packages])
  end
  let(:manage_bcf_role) do
    FactoryBot.create(
      :role,
      permissions: %i[manage_bcf view_linked_issues view_work_packages edit_work_packages add_work_packages]
    )
  end
  let(:bcf_manager) { FactoryBot.create(:user) }
  let(:workflow) do
    FactoryBot.create(:workflow_with_default_status,
                      role: manage_bcf_role,
                      type: type)
  end
  let(:priority) { FactoryBot.create :default_priority }
  let(:bcf_manager_member) do
    FactoryBot.create(:member,
                      project: project,
                      user: bcf_manager,
                      roles: [manage_bcf_role, member_role])
  end

  subject { described_class.new file, project, current_user: bcf_manager }

  before do
    workflow
    priority
    bcf_manager_member
    login_as(bcf_manager)
  end

  describe '#to_listing' do
    context 'without sufficient permissions' do
      context 'no add_work_packages permission' do
        pending 'test that importing user has add_work_packages permission'
      end

      context 'no manage_members permission' do
        pending 'test that non members should not be able to prepare an import'
      end
    end
  end

  describe '#import!' do
    it 'imports successfully' do
      expect(subject.import!).to be_present
    end

    it 'creates 2 work packages' do
      subject.import!

      expect(::Bim::Bcf::Issue.count).to be_eql 2
      expect(WorkPackage.count).to be_eql 2
    end
  end
end
