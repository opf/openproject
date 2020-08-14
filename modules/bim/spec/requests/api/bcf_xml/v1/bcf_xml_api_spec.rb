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
require 'rack/test'

describe 'BCF XML API v1 bcf_xml resource', type: :request do
  include Rack::Test::Methods

  let!(:status) { FactoryBot.create(:status, name: 'New', is_default: true) }
  let!(:type) { FactoryBot.create :type, name: 'Issue', is_standard: true, is_default: true }
  let!(:priority) { FactoryBot.create(:issue_priority, name: "Mega high", is_default: true) }
  let!(:project) { FactoryBot.create(:project, enabled_module_names: %w[bim work_package_tracking], types: [type]) }

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role, firstname: "BIMjamin")
  end
  let(:work_package) { FactoryBot.create(:work_package, status: status, priority: priority, project: project) }
  let(:bcf_issue) { FactoryBot.create(:bcf_issue_with_comment, work_package: work_package) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i(view_work_packages view_linked_issues) }
  let(:filename) { 'MaximumInformation.bcf' }
  let(:bcf_xml_file) do
    Rack::Test::UploadedFile.new(
      File.join(Rails.root, "modules/bim/spec/fixtures/files/#{filename}"),
      'application/octet-stream'
    )
  end

  subject(:response) { last_response }

  before do
    login_as(current_user)

    OpenProject::Cache.clear
  end

  describe 'GET /api/bcf_xml_api/v1/projects/<project>/bcf_xml' do
    let(:path) { "/api/bcf_xml_api/v1/projects/#{project.identifier}/bcf_xml" }

    context 'without params' do
      before do
        bcf_issue

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
          .to match(/attachment; filename="OpenProject_Work_packages_\d\d\d\d-\d\d-\d\d.bcf"/)
      end

      it 'responds with a correct .bcf file in the body ' do
        expect(zip_has_file?(subject.body, 'bcf.version')).to be_truthy
        expect(zip_has_file?(subject.body, "#{bcf_issue.uuid}/markup.bcf")).to be_truthy
      end

      context "without :view_linked_issues permission" do
        let(:permissions) { %i[view_work_packages] }

        it "returns a status 404" do
          expect(subject.status).to eql(404)
        end
      end
    end

    context 'with params filter on work package subject' do
      let(:escaped_query_params) do
        CGI.escape("[{\"subject\":{\"operator\":\"!~\",\"values\":[\"#{work_package.subject}\"]}}]")
      end
      let(:path) do
        "/api/bcf_xml_api/v1/projects/#{project.identifier}/bcf_xml?filters=#{escaped_query_params}"
      end

      before do
        bcf_issue

        get path
      end

      it 'excludes the work package from the .bcf file' do
        expect(zip_has_file?(subject.body, "#{bcf_issue.uuid}/markup.bcf")).to be_falsey
      end
    end
  end

  describe 'POST /api/bcf_xml_api/v1/projects/<project>/bcf_xml' do
    let(:permissions) { %i(view_work_packages add_work_packages edit_work_packages manage_bcf view_linked_issues) }
    let(:path) { "/api/bcf_xml_api/v1/projects/#{project.identifier}/bcf_xml" }
    let(:params) do
      {
        bcf_xml_file: bcf_xml_file
      }
    end

    before do
      work_package

      expect(project.work_packages.count).to eql(1)
      post path, params, 'CONTENT_TYPE' => 'multipart/form-data'
    end

    context 'without import conflicts' do
      it "creates two new work packages" do
        expect(subject.status).to eql(201)
        expect(project.work_packages.count).to eql(3)
      end
    end

    context "without :manage_bcf permission" do
      let(:permissions) do
        %i[view_work_packages add_work_packages edit_work_packages view_linked_issues]
      end

      it "returns a status 404" do
        expect(subject.status).to eql(404)
        expect(project.work_packages.count).to eql(1)
      end
    end

    context "with unsupported BCF version (2.0)" do
      let(:filename) { 'bcf_2_0_dummy.bcf' }

      it "returns a status 415" do
        expect(subject.status).to eql(415)
        expect(subject.body).to match /BCF version is not supported/
        expect(project.work_packages.count).to eql(1)
      end
    end
  end

  def zip_has_file?(zip_string, filename)
    has_file = false
    Zip::File.open_buffer(zip_string) do |zip_file|
      has_file = zip_file.find { |entry| entry.name == filename }.present?
    end
    has_file
  end
end
