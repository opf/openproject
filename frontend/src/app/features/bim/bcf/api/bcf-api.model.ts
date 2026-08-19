//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

export interface BcfComponent {
  ifc_guid:string|null
  originating_system:string|null
  authoring_tool_id:string|null
}

export interface BcfViewSetupHints {
  spaces_visible:boolean
  space_boundaries_visible:boolean
  openings_visible:boolean
}

export interface BcfColoring {
  color:string,
  components:BcfComponent[],
}

export interface BcfViewpointColoring {
  coloring:BcfColoring[]
}

export interface BcfViewpointSelection {
  selection:BcfComponent[]
}

export interface BcfViewpointVisibility {
  visibility:{
    default_visibility:boolean
    exceptions:BcfComponent[]
    view_setup_hints:BcfViewSetupHints|null
  }
}

export interface BcfOrthogonalCamera {
  camera_view_point:{ x:number, y:number, z:number }
  camera_direction:{ x:number, y:number, z:number }
  camera_up_vector:{ x:number, y:number, z:number }
  view_to_world_scale:number
}

export interface BcfPerspectiveCamera {
  camera_view_point:{ x:number, y:number, z:number }
  camera_direction:{ x:number, y:number, z:number }
  camera_up_vector:{ x:number, y:number, z:number }
  field_of_view:number
}

export interface BcfBitmap {
  guid:string
  bitmap_type:string
  location:{ x:number, y:number, z:number }
  normal:{ x:number, y:number, z:number }
  up:{ x:number, y:number, z:number }
  height:number
}

export interface BcfClippingPlane {
  location:{ x:number, y:number, z:number }
  direction:{ x:number, y:number, z:number }
}

export interface BcfLine {
  start_point:{ x:number, y:number, z:number }
  end_point:{ x:number, y:number, z:number }
}

export interface BcfViewpoint {
  index:number|null
  guid:string
  orthogonal_camera:BcfOrthogonalCamera|null
  perspective_camera:BcfPerspectiveCamera|null
  lines:BcfLine[]|null
  clipping_planes:BcfClippingPlane[]|null
  bitmaps:BcfBitmap[]|null
  snapshot:{ snapshot_type:string }
}

export type BcfViewpointData = BcfViewpoint&{
  components:BcfViewpointVisibility&BcfViewpointSelection&BcfViewpointColoring
};

export type CreateBcfViewpointData = BcfViewpointData&{
  snapshot:{ snapshot_type:string, snapshot_data:string }
};
