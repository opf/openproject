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

describe Bim::Bcf::Viewpoints::CreateContract do
  let(:viewpoint) do
    Bim::Bcf::Viewpoint.new(uuid: viewpoint_uuid,
                       issue: viewpoint_issue,
                       json_viewpoint: viewpoint_json_viewpoint)
  end
  let(:permissions) { [:manage_bcf] }

  subject(:contract) { described_class.new(viewpoint, current_user) }

  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end
  let!(:allowed_to) do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, permission_project|
      permissions.include?(permission) && project == permission_project
    end
  end
  let(:viewpoint_uuid) { 'issue uuid' }
  let(:viewpoint_json_viewpoint) do
    {
      'snapshot' => {
        'snapshot_data' => 'some contents',
        'snapshot_type' => 'jpg'
      }
    }
  end
  let(:viewpoint_issue) do
    FactoryBot.build_stubbed(:bcf_issue).tap do |issue|
      allow(issue)
        .to receive(:project)
        .and_return(project)
    end
  end
  let(:project) { FactoryBot.build_stubbed(:project) }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  it_behaves_like 'is valid'

  context 'if the uuid is nil' do
    let(:issue_uuid) { nil }

    it_behaves_like 'is valid' # as the uuid will be set
  end

  context 'if the issue is nil' do
    let(:viewpoint_issue) { nil }

    it 'is invalid' do
      expect_valid(false, issue: %i(blank))
    end
  end

  context 'if the json_viewpoint is nil' do
    let(:viewpoint_json_viewpoint) { nil }

    it 'is invalid' do
      expect_valid(false, json_viewpoint: %i(blank))
    end
  end

  context 'if the user lacks permission' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context 'json_viewpoint' do
    context 'with something different that a hash' do
      let(:viewpoint_json_viewpoint) do
        'some non hash'
      end

      it 'is invalid' do
        expect_valid(false, json_viewpoint: %i(no_json))
      end
    end

    context 'with an unsupported key' do
      let(:viewpoint_json_viewpoint) do
        {
          'some_key' => true
        }
      end

      it 'is invalid' do
        expect_valid(false, json_viewpoint: %i(unsupported_key))
      end
    end

    describe 'snapshot' do
      let(:viewpoint_json_viewpoint) do
        {
          'snapshot' => {
            'snapshot_data' => 'some content',
            'snapshot_type' => 'jpg'
          }
        }
      end

      it_behaves_like 'is valid'

      context 'with a type other than png or jpg' do
        let(:viewpoint_json_viewpoint) do
          {
            'snapshot' => {
              'snapshot_data' => 'some content',
              'snapshot_type' => 'some'
            }
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(snapshot_type_unsupported))
        end
      end

      context 'without a type' do
        let(:viewpoint_json_viewpoint) do
          {
            'snapshot' => {
              'snapshot_data' => 'some content'
            }
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(snapshot_type_unsupported))
        end
      end

      context 'without data' do
        let(:viewpoint_json_viewpoint) do
          {
            'snapshot' => {
              'snapshot_type' => 'jpg'
            }
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(snapshot_data_blank))
        end
      end

      context 'without snapshot' do
        let(:viewpoint_json_viewpoint) do
          {
            "index": 10
          }
        end

        it_behaves_like 'is valid'
      end
    end

    describe 'index' do
      context 'with a non integer value' do
        let(:viewpoint_json_viewpoint) do
          {
            'index' => 'something'
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(index_not_integer))
        end
      end
    end

    describe 'orthogonal_camera' do
      let(:valid_json) do
        {
          "orthogonal_camera": {
            "camera_view_point": {
              "x": 12.3456789,
              "y": 1.2345,
              "z": -1234.1234
            },
            "camera_direction": {
              "x": -1.0,
              "y": -2.0,
              "z": -3.0
            },
            "camera_up_vector": {
              "x": 0.223629,
              "y": 0.209889,
              "z": 0.951807
            },
            "view_to_world_scale": 2.0
          }
        }.stringify_keys
      end

      let(:viewpoint_json_viewpoint) do
        valid_json
      end

      it_behaves_like 'is valid'

      context 'with an additional property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['orthogonal_camera']['superfluous_property'] = 123
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_orthogonal_camera))
        end
      end

      context 'with a missing property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['orthogonal_camera'].delete(:camera_direction)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_orthogonal_camera))
        end
      end

      context 'with a missing dimension in one of the directions' do
        let(:viewpoint_json_viewpoint) do
          valid_json['orthogonal_camera'][:camera_direction].delete(:y)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_orthogonal_camera))
        end
      end

      context 'with a non number in one of the directions' do
        let(:viewpoint_json_viewpoint) do
          valid_json['orthogonal_camera'][:camera_direction][:z] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_orthogonal_camera))
        end
      end

      context 'with a non number in for view_to_world_scale' do
        let(:viewpoint_json_viewpoint) do
          valid_json['orthogonal_camera'][:view_to_world_scale] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_orthogonal_camera))
        end
      end
    end

    describe 'perspective_camera' do
      let(:valid_json) do
        {
          "perspective_camera": {
            "camera_view_point": {
              "x": 12.3456789,
              "y": 1.2345,
              "z": -1234.1234
            },
            "camera_direction": {
              "x": -1.0,
              "y": -2.0,
              "z": -3.0
            },
            "camera_up_vector": {
              "x": 0.223629,
              "y": 0.209889,
              "z": 0.951807
            },
            "field_of_view": 180.0
          }
        }.stringify_keys
      end

      let(:viewpoint_json_viewpoint) do
        valid_json
      end

      it_behaves_like 'is valid'

      context 'with an additional property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['perspective_camera']['superfluous_property'] = 123
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_perspective_camera))
        end
      end

      context 'with a missing property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['perspective_camera'].delete(:camera_direction)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_perspective_camera))
        end
      end

      context 'with a missing dimension in one of the directions' do
        let(:viewpoint_json_viewpoint) do
          valid_json['perspective_camera'][:camera_direction].delete(:y)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_perspective_camera))
        end
      end

      context 'with a non number in one of the directions' do
        let(:viewpoint_json_viewpoint) do
          valid_json['perspective_camera'][:camera_direction][:z] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_perspective_camera))
        end
      end

      context 'with a non number in for view_to_world_scale' do
        let(:viewpoint_json_viewpoint) do
          valid_json['perspective_camera'][:field_of_view] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_perspective_camera))
        end
      end
    end

    describe 'lines' do
      let(:valid_json) do
        {
          "lines": [
            {
              "start_point": {
                "x": 1.0,
                "y": 1.0,
                "z": 1.0
              },
              "end_point": {
                "x": 0.0,
                "y": 0.0,
                "z": 0.0
              }
            },
            {
              "start_point": {
                "x": 2.0,
                "y": 3.0,
                "z": 4.0
              },
              "end_point": {
                "x": -1.0,
                "y": -2.0,
                "z": -3.0
              }
            }
          ]
        }.stringify_keys
      end

      let(:viewpoint_json_viewpoint) do
        valid_json
      end

      it_behaves_like 'is valid'

      context 'with a non array for lines' do
        let(:viewpoint_json_viewpoint) do
          {
            "lines" => { "some" => "value" }
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_lines))
        end
      end

      context 'with an additional property for one line' do
        let(:viewpoint_json_viewpoint) do
          valid_json['lines'][1]['superfluous_property'] = 123
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_lines))
        end
      end

      context 'with a missing property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['lines'][1].delete(:start_point)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_lines))
        end
      end

      context 'with a missing dimension in one of the lines' do
        let(:viewpoint_json_viewpoint) do
          valid_json['lines'][1][:end_point].delete(:y)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_lines))
        end
      end

      context 'with a non number in one of the points' do
        let(:viewpoint_json_viewpoint) do
          valid_json['lines'][1][:start_point][:z] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_lines))
        end
      end
    end

    describe 'clipping_planes' do
      let(:valid_json) do
        {
          "clipping_planes": [
            {
              "location": {
                "x": 0.5,
                "y": 0.5,
                "z": 0.5
              },
              "direction": {
                "x": 1.0,
                "y": 0.0,
                "z": 0.0
              }
            },
            {
              "location": {
                "x": 4.5,
                "y": 0.5,
                "z": 1.5
              },
              "direction": {
                "x": 1.0,
                "y": -5.5,
                "z": 0.6
              }
            }
          ]
        }.stringify_keys
      end

      let(:viewpoint_json_viewpoint) do
        valid_json
      end

      it_behaves_like 'is valid'

      context 'with a non array for lines' do
        let(:viewpoint_json_viewpoint) do
          {
            "clipping_planes" => { "some" => "value" }
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_clipping_planes))
        end
      end

      context 'with an additional property for one line' do
        let(:viewpoint_json_viewpoint) do
          valid_json['clipping_planes'][1]['superfluous_property'] = 123
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_clipping_planes))
        end
      end

      context 'with a missing property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['clipping_planes'][1].delete(:direction)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_clipping_planes))
        end
      end

      context 'with a missing dimension in one of the lines' do
        let(:viewpoint_json_viewpoint) do
          valid_json['clipping_planes'][1][:direction].delete(:y)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_clipping_planes))
        end
      end

      context 'with a non number in one of the points' do
        let(:viewpoint_json_viewpoint) do
          valid_json['clipping_planes'][1][:location][:z] = "sdfjsdkf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_clipping_planes))
        end
      end
    end

    describe 'bitmaps' do
      let(:viewpoint_json_viewpoint) do
        {
          "bitmaps": [
            "something"
          ]
        }.stringify_keys
      end

      it 'is invalid' do
        expect_valid(false, json_viewpoint: %i(bitmaps_not_writable))
      end
    end

    describe 'components' do
      let(:valid_json) do
        {
          "components":
            {
              "selection": [
                {
                  "ifc_guid": "2MF28NhmDBiRVyFakgdbCT",
                  "originating_system": "Example CAD Application",
                  "authoring_tool_id": "EXCAD/v1.0"
                },
                {
                  "ifc_guid": "4MF28NhmDBiRVyFakgdbCT",
                  "originating_system": "Example CAD Application",
                  "authoring_tool_id": "EXCAD/v1.0"
                }
              ],
              "coloring": [
                {
                  "color": "#ff0000",
                  "components": [
                    {
                      "ifc_guid": "3$cshxZO9AJBebsni$z9Yk"
                    },
                    {
                      "ifc_guid": "4$cshxZO9AJBebsni$z9Yk"
                    }
                  ]
                },
                {
                  "color": "#ff0333",
                  "components": [
                    {
                      "ifc_guid": "3$cshxZO9AJBebsni$z9Y8"
                    },
                    {
                      "ifc_guid": "4$cshxZO9AJBebsni$z9Y8"
                    }
                  ]
                }
              ],
              "visibility": {
                "default_visibility": false,
                "exceptions": [
                  {
                    "ifc_guid": "4$cshxZO9AJBebsni$z9Yk"
                  }
                ],
                "view_setup_hints": {
                  "spaces_visible": true,
                  "space_boundaries_visible": false,
                  "openings_visible": true
                }
              }
            }
        }.stringify_keys
      end

      let(:viewpoint_json_viewpoint) do
        valid_json
      end

      it_behaves_like 'is valid'

      context 'with a non hash' do
        let(:viewpoint_json_viewpoint) do
          {
            "components" => 534
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with an additional property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components']['superfluous_property'] = 123
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with missing visibility property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'].delete(:visibility)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with missing selection property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'].delete(:selection)
          valid_json
        end

        it_behaves_like 'is valid'
      end

      context 'with missing coloring property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'].delete(:coloring)
          valid_json
        end

        it_behaves_like 'is valid'
      end

      context 'with selection property not being an array of hashes' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:selection] = ["blubs"]
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with a property of the selection property not being string' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:selection][1][:ifcguid] = 345
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with a component of the selection property having an unkonwn property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:selection][1]['superfluous'] = "sdsdsf"
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with a component of the selection property being empty' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:selection][1] = {}
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with coloring property not being an array of hashes' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring] = ["blubs"]
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with a coloring of the coloring property lacking a property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring][1].delete(:color)
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with having an invalid color for coloring property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring][1][:color] = '#ff54zzzz'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with having a non string for color of a coloring property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring][1][:color] = 123456
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with having a non array of hashes for components of a coloring property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring][1][:components] = ['blubs']
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with having an invalid property in for a components of a coloring property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:coloring][1][:components][0]['superfluous'] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with visibility property not being a hashes' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with visibility property having an unknown property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility]['superfluous'] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with visibility property being an empty hash' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility] = {}
          valid_json
        end

        it_behaves_like 'is valid'
      end

      context 'with visibility property lacking a property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility].delete(:exceptions)
          valid_json
        end

        it_behaves_like 'is valid'
      end

      context 'with default_visibility of the visibility property being a non boolean' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:default_visibility] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with components of the visibility property not being an array of hashes' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:exceptions] = ['blubs']
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with components of the visibility property having an invalid property' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:exceptions][0]['superfluous'] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with on property of a components of the visibility property being a non string' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:exceptions][0][:originating_system] = 124
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with view_setup_hints not being a hash' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:view_setup_hints] = []
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with view_setup_hints being an empty hash' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:view_setup_hints] = {}
          valid_json
        end

        it_behaves_like 'is valid'
      end

      context 'with view_setup_hints having an unknown parameter' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:view_setup_hints]['superfluous'] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end

      context 'with a property of view_setup_hints being a non boolean' do
        let(:viewpoint_json_viewpoint) do
          valid_json['components'][:visibility][:view_setup_hints][:openings_visible] = 'blubs'
          valid_json
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(invalid_components))
        end
      end
    end

    describe 'guid' do
      context 'with the same value the model has' do
        let(:viewpoint_json_viewpoint) do
          {
            'guid' => viewpoint_uuid
          }
        end

        it_behaves_like 'is valid'
      end

      context 'with a different value than the model has' do
        let(:viewpoint_json_viewpoint) do
          {
            'guid' => viewpoint_uuid + 'something'
          }
        end

        it 'is invalid' do
          expect_valid(false, json_viewpoint: %i(mismatching_guid))
        end
      end
    end
  end
end
