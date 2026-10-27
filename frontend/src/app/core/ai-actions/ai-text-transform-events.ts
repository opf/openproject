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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

export type AiTextTransformScope = 'document'|'selection';

export interface AiTextTransformApplyDetail {
  requestId:string;
  scope:AiTextTransformScope;
  text:string;
}

export interface AiTextTransformAppliedDetail {
  requestId:string;
  ok:boolean;
}

export const AI_TEXT_TRANSFORM_APPLIED_EVENT = 'op:ai-text-transform:applied';
// Dispatched by the server through the dispatchEvent turbo stream action.
export const AI_TEXT_TRANSFORM_APPLY_EVENT = 'op-dispatched:ai-text-transform:accepted';
export const AI_TEXT_TRANSFORM_CLOSED_EVENT = 'op-dispatched:ai-text-transform:closed';
