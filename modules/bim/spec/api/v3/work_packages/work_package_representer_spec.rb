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

  let(:project) do
    work_package.project
  end
  let(:permissions) { %i[view_linked_issues view_work_packages] }
  let(:user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |queried_permissison, queried_project|
        queried_project == work_package.project &&
          permissions.include?(queried_permissison)
      end
    end
  end
  let(:bcf_issue) do
    FactoryBot.build_stubbed(:bcf_issue_with_comment)
  end
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package, bcf_issue: bcf_issue)
  end
  let(:representer) do
    described_class.new(work_package,
                        current_user: user,
                        embed_links: true)
  end

  before(:each) do
    login_as user
  end

  subject(:generated) { representer.to_json }

  include_context 'eager loaded work package representer'

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
