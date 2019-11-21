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
      is_expected.to be_json_eql([
        {
          file_name: bcf_issue.viewpoints.first.attachments.first.filename,
          id: bcf_issue.viewpoints.first.attachments.first.id
        }
      ].to_json)
        .including('id')
        .at_path('bcf/viewpoints/')
    end
  end
end
