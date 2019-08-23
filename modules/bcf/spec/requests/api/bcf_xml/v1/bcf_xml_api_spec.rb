#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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
require 'rack/test'

describe 'BCF XML API v1 bcf_xml resource', type: :request do
  include Rack::Test::Methods

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:work_package) { FactoryBot.create(:work_package) }
  let(:project) { work_package.project }
  let(:bcf_issue) { FactoryBot.create(:bcf_issue_with_comment, work_package: work_package) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i(view_work_packages view_associated_issues) }

  subject(:response) { last_response }

  before do
    login_as(current_user)

    OpenProject::Cache.clear
  end

  describe 'GET /bcf_xml_api/v1/projects/<project>/bcf_xml' do
    let(:path) { "/bcf_xml_api/v1/projects/#{project.identifier}/bcf_xml" }

    context 'without params' do
      before do
        get path
      end

      it 'responds 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'responds with correct Content-Type' do
        expect(subject.content_type)
          .to eql("application/octet-stream")
      end

      it 'responds with correct Content-Disposition' do
        expect(subject.header["Content-Disposition"])
          .to match(/attachment; filename="OpenProject_Work_packages_\d\d\d\d-\d\d-\d\d.bcfzip"/)
      end

      it 'responds with a .bcfzip file in the body ' do
        bcf_issue

        expect(zip_has_file?(subject.body, 'bcf.version')).to be_truthy
      end
    end
  end

  def zip_has_file?(zip_string, filename)
    has_bcf_version_file = false
    Zip::File.open_buffer(zip_string) do |zip_io|
      has_bcf_version_file = zip_io.find { |entry| entry.name == filename }.present?
    end
    has_bcf_version_file
  end
end
