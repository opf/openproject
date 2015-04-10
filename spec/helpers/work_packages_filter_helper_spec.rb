#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

describe WorkPackagesFilterHelper, type: :helper do
  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version, project: project) }

  describe '#general_path_helpers' do

    it 'should give the path to work packages index with property filter' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"v\":2,\"n\":\"status_id\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_property_path(project, 'status_id', 2))).to eq expectedDecoded
    end

  end

  describe '#my_page_path_helpers' do

    it 'should give the path to work packages assigned to me' do
      expectedDecoded = "/work_packages?query_props={\"f\":[{\"v\":\"me\",\"n\":\"assigned_to_id\",\"o\":\"=\"},{\"n\":\"status_id\",\"o\":\"o\"}],\"t\":\"priority:desc,updated_at:desc\"}"
      expect(CGI::unescape(helper.work_packages_assigned_to_me_path)).to eq expectedDecoded
    end

    it 'should give the path to work packages reported by me' do
      expectedDecoded = "/work_packages?query_props={\"f\":[{\"v\":\"me\",\"n\":\"author_id\",\"o\":\"=\"},{\"n\":\"status_id\",\"o\":\"*\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.work_packages_reported_by_me_path)).to eq expectedDecoded
    end

    it "should give the path to work packages I'm responsible for" do
      expectedDecoded = "/work_packages?query_props={\"f\":[{\"v\":\"me\",\"n\":\"responsible_id\",\"o\":\"=\"},{\"n\":\"status_id\",\"o\":\"o\"}],\"t\":\"priority:desc,updated_at:desc\"}"
      expect(CGI::unescape(helper.work_packages_responsible_for_path)).to eq expectedDecoded
    end

    it 'should give the path to work packages watched by me' do
      expectedDecoded = "/work_packages?query_props={\"f\":[{\"v\":\"me\",\"n\":\"watcher_id\",\"o\":\"=\"},{\"n\":\"status_id\",\"o\":\"o\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.work_packages_watched_path)).to eq expectedDecoded
    end

  end

  describe '#project_overview_path_helpers' do

    it 'should give the path to closed work packages for a project version' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"c\"},{\"v\":" + version.id.to_s + ",\"n\":\"fixed_version_id\",\"o\":\"=\"}]}"
      expect(CGI::unescape(helper.project_work_packages_closed_version_path(version))).to eq expectedDecoded
    end

    it 'should give the path to open work packages for a project version' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"o\"},{\"v\":" + version.id.to_s + ",\"n\":\"fixed_version_id\",\"o\":\"=\"}]}"
      expect(CGI::unescape(helper.project_work_packages_open_version_path(version))).to eq expectedDecoded
    end

  end

  describe '#project_reports_path_helpers' do
    let(:property_name) { 'priority_id' }
    let(:property_id) { 5 }

    it 'should give the path to work packages for a report property' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"*\"},{\"n\":\"subproject_id\",\"o\":\"!*\"},{\"v\":" + property_id.to_s + ",\"n\":\"" + property_name + "\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_report_property_path(project, property_name, property_id))).to eq expectedDecoded
    end

    it 'should give the path to work packages for a report property with status' do
      status_id = 2
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"v\":" + status_id.to_s + ",\"n\":\"status_id\",\"o\":\"=\"},{\"n\":\"subproject_id\",\"o\":\"!*\"},{\"v\":" + property_id.to_s + ",\"n\":\"" + property_name + "\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_report_property_status_path(project, status_id, property_name, property_id))).to eq expectedDecoded
    end

    it 'should give the path to open work packages for a report property' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"o\"},{\"n\":\"subproject_id\",\"o\":\"!*\"},{\"v\":" + property_id.to_s + ",\"n\":\"" + property_name + "\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_report_property_open_path(project, property_name, property_id))).to eq expectedDecoded
    end

    it 'should give the path to closed work packages for a report property' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"c\"},{\"n\":\"subproject_id\",\"o\":\"!*\"},{\"v\":" + property_id.to_s + ",\"n\":\"" + property_name + "\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_report_property_closed_path(project, property_name, property_id))).to eq expectedDecoded
    end

    it 'should give the path to work packages for a report property belonging to a project version' do
      expectedDecoded = '/projects/' + project.identifier + "/work_packages?query_props={\"f\":[{\"n\":\"status_id\",\"o\":\"*\"},{\"v\":" + version.id.to_s + ",\"n\":\"fixed_version_id\",\"o\":\"=\"},{\"v\":" + property_id.to_s + ",\"n\":\"" + property_name + "\",\"o\":\"=\"}],\"t\":\"updated_at:desc\"}"
      expect(CGI::unescape(helper.project_version_property_path(version, property_name, property_id))).to eq expectedDecoded
    end

  end
end
