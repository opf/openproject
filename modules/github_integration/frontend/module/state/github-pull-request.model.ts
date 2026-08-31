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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';
import { ID } from '@datorama/akita';

export interface ISnippet {
  id:string;
  name:string;
  multiline?:boolean;
  text:() => string;
}

export interface IGithubUserResource {
  avatarUrl:string;
  htmlUrl:string;
  login:string;
}

export interface IGithubCheckRunResource {
  appOwnerAvatarUrl:string;
  completedAt:string;
  conclusion:string;
  detailsUrl:string;
  htmlUrl:string;
  name:string;
  outputSummary:string;
  outputTitle:string;
  startedAt:string;
  status:string;
}

export interface IGithubPullRequestResourceLinks extends IHalResourceLinks {
  githubUser:IHalResourceLink;
  mergedBy?:IHalResourceLink;
  checkRuns?:IHalResourceLink[];
}

export interface IGithubPullRequestResourceEmbedded {
  githubUser:IGithubUserResource;
  mergedBy?:IGithubUserResource;
  checkRuns:IGithubCheckRunResource[];
}

export interface IGithubPullRequest {
  id:ID;
  additionsCount?:number;
  body?:{
    format?:string;
    raw?:string;
    html?:string;
  },
  changedFilesCount?:number;
  commentsCount?:number;
  createdAt?:string;
  deletionsCount?:number;
  draft?:boolean;
  githubUpdatedAt?:string;
  htmlUrl:string;
  labels?:string[];
  merged?:boolean;
  mergedAt?:string;
  number?:number;
  repository:string;
  repositoryHtmlUrl:string;
  reviewCommentsCount?:number;
  state?:string;
  title:string;
  updatedAt?:string;

  _links:IGithubPullRequestResourceLinks;
  _embedded:IGithubPullRequestResourceEmbedded;
}
