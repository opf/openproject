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

describe WorkPackagesFilterHelper, type: :helper do
  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version, project: project) }
  let(:global) { false }

  shared_examples_for 'work package path with query_props' do
    it 'is the expected path' do
      path_regexp = if global
                      Regexp.new("^#{work_packages_path}\\?query_props=(.*)")
                    else
                      Regexp.new("^#{project_work_packages_path(project.identifier)}\\?query_props=(.*)")
                    end

      expect(path)
        .to match path_regexp

      query_props = CGI::unescape(path.match(path_regexp)[1])

      expect(JSON.parse(query_props))
        .to eql(expected_json.with_indifferent_access)
    end
  end

  describe '#project_property_path' do
    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'status',
              o: '=',
              v: '2'
            }
          ],
          t: 'updated_at:desc'
        }
      end

      let(:path) { helper.project_property_path(project, 'status_id', 2) }
    end
  end

  describe '#work_packages_assigned_to_me_path' do
    let(:global) { true }

    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'assignee',
              o: '=',
              v: 'me'
            },
            {
              n: 'status',
              o: 'o'
            }
          ],
          t: 'priority:desc,updated_at:desc'
        }
      end

      let(:path) { helper.work_packages_assigned_to_me_path }
    end
  end

  describe '#work_packages_reported_by_me_path' do
    let(:global) { true }

    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'author',
              o: '=',
              v: 'me'
            },
            {
              n: 'status',
              o: '*'
            }
          ],
          t: 'updated_at:desc'
        }
      end

      let(:path) { helper.work_packages_reported_by_me_path }
    end
  end

  describe '#work_packages_responsible_for_path' do
    let(:global) { true }

    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'responsible',
              o: '=',
              v: 'me'
            },
            {
              n: 'status',
              o: 'o'
            }
          ],
          t: 'priority:desc,updated_at:desc'
        }
      end

      let(:path) { helper.work_packages_responsible_for_path }
    end
  end

  describe '#work_packages_watched_path' do
    let(:global) { true }

    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'watcher',
              o: '=',
              v: 'me'
            },
            {
              n: 'status',
              o: 'o'
            }
          ],
          t: 'updated_at:desc'
        }
      end

      let(:path) { helper.work_packages_watched_path }
    end
  end

  describe '#project_work_packages_closed_version_path' do
    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'status',
              o: 'c'
            },
            {
              n: 'version',
              o: '=',
              v: version.id.to_s
            }
          ]
        }
      end

      let(:path) { helper.project_work_packages_closed_version_path(version) }
    end
  end

  describe '#project_work_packages_open_version_path' do
    it_behaves_like 'work package path with query_props' do
      let(:expected_json) do
        {
          f: [
            {
              n: 'status',
              o: 'o'
            },
            {
              n: 'version',
              o: '=',
              v: version.id.to_s
            }
          ]
        }
      end

      let(:path) { helper.project_work_packages_open_version_path(version) }
    end
  end

  context 'project reports path helpers' do
    let(:property_name) { 'priority' }
    let(:property_id) { 5 }

    describe '#project_report_property_path' do
      it_behaves_like 'work package path with query_props' do
        let(:expected_json) do
          {
            f: [
              {
                n: 'status',
                o: '*'
              },
              {
                n: 'subprojectId',
                o: '!*'
              },
              {
                n: property_name,
                o: '=',
                v: property_id.to_s
              }
            ],
            t: 'updated_at:desc'
          }
        end

        let(:path) { helper.project_report_property_path(project, property_name, property_id) }
      end
    end

    describe '#project_report_property_status_path' do
      it_behaves_like 'work package path with query_props' do
        let(:status_id) { 2 }
        let(:expected_json) do
          {
            f: [
              {
                n: 'status',
                o: '=',
                v: status_id.to_s
              },
              {
                n: 'subprojectId',
                o: '!*'
              },
              {
                n: property_name,
                o: '=',
                v: property_id.to_s
              }
            ],
            t: 'updated_at:desc'
          }
        end

        let(:path) { helper.project_report_property_status_path(project, status_id, property_name, property_id) }
      end
    end

    describe '#project_report_property_open_path' do
      it_behaves_like 'work package path with query_props' do
        let(:expected_json) do
          {
            f: [
              {
                n: 'status',
                o: 'o'
              },
              {
                n: 'subprojectId',
                o: '!*'
              },
              {
                n: property_name,
                o: '=',
                v: property_id.to_s
              }
            ],
            t: 'updated_at:desc'
          }
        end

        let(:path) { helper.project_report_property_open_path(project, property_name, property_id) }
      end
    end

    describe '#project_report_property_closed_path' do
      it_behaves_like 'work package path with query_props' do
        let(:expected_json) do
          {
            f: [
              {
                n: 'status',
                o: 'c'
              },
              {
                n: 'subprojectId',
                o: '!*'
              },
              {
                n: property_name,
                o: '=',
                v: property_id.to_s
              }
            ],
            t: 'updated_at:desc'
          }
        end

        let(:path) { helper.project_report_property_closed_path(project, property_name, property_id) }
      end
    end

    describe '#project_version_property_path' do
      it_behaves_like 'work package path with query_props' do
        let(:expected_json) do
          {
            f: [
              {
                n: 'status',
                o: '*'
              },
              {
                n: 'version',
                o: '=',
                v: version.id.to_s
              },
              {
                n: property_name,
                o: '=',
                v: property_id.to_s
              }
            ],
            t: 'updated_at:desc'
          }
        end

        let(:path) { helper.project_version_property_path(version, property_name, property_id) }
      end
    end
  end
end
