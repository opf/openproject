//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2023 Ben Tey
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
// Copyright (C) the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { HalResourceClass } from 'core-app/modules/hal/resources/hal-resource';


export interface ISnippet {
  id:string;
  name:string;
  textToDisplay:()=>string;
  textToCopy:()=>string
}

export interface IGitlabIssueResource extends HalResourceClass {
  body?:{
    format?:string;
    raw?:string;
    html?:string;
  },
  createdAt?:string;
  gitlabUpdatedAt?:string;
  htmlUrl?:string;
  id?:number;
  labels?:string[];
  number?:number;
  repository?:string;
  state?:string;
  title?:string;
  updatedAt?:string;
  gitlabUser?:IGitlabUserResource;
}

export interface IGitlabMergeRequestResource extends HalResourceClass {
  body?:{
    format?:string;
    raw?:string;
    html?:string;
  },
  createdAt?:string;
  draft?:boolean;
  gitlabUpdatedAt?:string;
  htmlUrl?:string;
  id?:number;
  labels?:string[];
  merged?:boolean;
  mergedAt?:string;
  mergedBy?:IGitlabUserResource;
  number?:number;
  repository?:string;
  state?:string;
  title?:string;
  updatedAt?:string;
  gitlabUser?:IGitlabUserResource;
  pipelines?:IGitlabPipelineResource[];
}

export interface IGitlabUserResource {
  avatarUrl:string;
  email:string;
  login:string;
}

export interface IGitlabPipelineResource {
  userAvatarUrl:string;
  completedAt:string;
  detailsUrl:string;
  htmlUrl:string;
  name:string;
  startedAt:string;
  status:string;
  ci_details:string[];
  username:string;
  commitId:string;
}
