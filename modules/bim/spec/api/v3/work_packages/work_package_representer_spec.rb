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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:role) do
    FactoryBot.create(:role, permissions: %i[view_linked_issues view_work_packages])
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:bcf_issue) do
    FactoryBot.create(:bcf_issue_with_comment, work_package: work_package)
  end
  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id)
  end
  let(:representer) do
    described_class.new(work_package,
                        current_user: user,
                        embed_links: true)
  end

  before(:each) do
    allow(User).to receive(:current).and_return user
  end

  subject(:generated) { representer.to_json }

  describe 'with BCF issues' do
    it "contains viewpoints" do
      is_expected.to be_json_eql(
        {
          uuid: bcf_issue.uuid,
          viewpoints: [
            {
              uuid: bcf_issue.viewpoints.first.uuid,
              snapshot_file_name: bcf_issue.viewpoints.first.attachments.first.filename,
              snapshot_id: bcf_issue.viewpoints.first.attachments.first.id
            }
          ]
        }.to_json
      ).including('snapshot_id').at_path('bcf')
    end
  end
end
