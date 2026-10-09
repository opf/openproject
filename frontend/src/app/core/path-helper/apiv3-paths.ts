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

import { ApiV3FilterBuilder, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

type PrincipalsFilter = [string, FilterOperator, string[]];

export class ApiV3Paths {
  readonly apiV3Base:string;

  constructor(basePath:string) {
    this.apiV3Base = `${basePath}/api/v3`;
  }

  public get openApiSpecPath():string {
    return `${this.apiV3Base}/spec.json`;
  }

  /**
   * Preview markup path
   *
   * Primarily used from ckeditor-augmented-textarea
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   * @param context
   */
  public previewMarkup(context:string) {
    const base = `${this.apiV3Base}/render/markdown`;

    if (context) {
      return `${base}?context=${context}`;
    }
    return base;
  }

  public aiTextTransformActions() {
    return `${this.apiV3Base}/ai_text_transform_actions`;
  }

  public aiTextTransformActionsByWorkPackage(workPackageId:string|number) {
    return `${this.apiV3Base}/work_packages/${workPackageId}/ai_text_transform_actions`;
  }

  public aiTextTransformActionsByProject(projectId:string|number, typeId:string|number) {
    return `${this.apiV3Base}/projects/${projectId}/ai_text_transform_actions?typeId=${typeId}`;
  }

  public aiTextTransformRuns() {
    return `${this.apiV3Base}/ai_text_transform_runs`;
  }

  public aiTextTransformRun(uuid:string) {
    return `${this.aiTextTransformRuns()}/${uuid}`;
  }

  public aiTextTransformRunCancel(uuid:string) {
    return `${this.aiTextTransformRun(uuid)}/cancel`;
  }

  /**
   * Principals autocompleter path, or null when the resource offers no user mentions
   *
   * Primarily used from ckeditor-augmented-textarea
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   */
  public principals(resource:HalResource, term:string|null):string|null {
    const mentionable = this.mentionableFilter(resource);
    if (!mentionable) {
      return null;
    }

    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    // Only real and activated users:
    filters.add('status', '!', ['3']);
    filters.add(...mentionable);
    // That are users:
    filters.add('type', '=', ['User', 'Group']);

    if (term && term.length > 0) {
      // Containing the that substring:
      filters.add('name', '~', [term]);
    }

    return `${this.apiV3Base}/principals?${filters.toParams({ sortBy: '[["name","asc"]]', offset: '1', pageSize: '10' })}`;
  }

  private mentionableFilter(resource:HalResource):PrincipalsFilter|null {
    const isNew = !resource.id || resource.id === 'new';

    switch (resource._type) {
      case 'WorkPackage':
        if (isNew) {
          return this.projectMembersFilter(resource);
        }
        return [
          this.isInternalMentionable() ? 'internal_mentionable_on_work_package' : 'mentionable_on_work_package',
          '=',
          [resource.id!],
        ];
      case 'Post':
        return isNew ? this.projectMembersFilter(resource) : ['mentionable_on_message', '=', [resource.id!]];
      default:
        return null;
    }
  }

  private projectMembersFilter(resource:HalResource):PrincipalsFilter {
    return ['member', '=', [(resource.project as HalResource).id!]];
  }

  /**
   * Check if either adding or editing a comment is internal, and thus
   * the mentionable principals are to be internal
   *
   * @returns {boolean}
   */
  private isInternalMentionable():boolean {
    const isInternalAttributeValue = 'data-work-packages--activities-tab--internal-comment-is-internal-value';
    const addingCommentIsInternal = document.getElementById('work-packages-activities-tab-add-comment-component')?.getAttribute(isInternalAttributeValue) === 'true';
    const editingCommentIsInternal = document.querySelector('.work-packages-activities-tab-journals-item-component-edit')?.getAttribute(isInternalAttributeValue) === 'true';

    return addingCommentIsInternal || editingCommentIsInternal;
  }
}
