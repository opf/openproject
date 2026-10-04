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

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HighlightingRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/row-highlight-render-pass';
import { DragDropHandleRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-render-pass';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { timeOutput } from 'core-app/shared/helpers/debug_output';
import { TimelineRenderPass } from './timeline/timeline-render-pass';
import { SingleRowBuilder } from './rows/single-row-builder';
import { RelationsRenderPass } from './relations/relations-render-pass';
import { WorkPackageTable } from '../wp-fast-table';
import {
  ChildRelationsRenderPass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/relations/child-relations-render-pass';
import invariant from 'tiny-invariant';
import {
  type DraftOccurrence,
  type OccurrenceKey,
  type RenderDraft,
  type RenderedOccurrence,
  placeholderOccurrenceKey,
  wpOccurrenceKey,
} from 'core-app/features/work-packages/components/wp-fast-table/rendered-occurrence-ledger';

export interface RenderPassOptions {
  timeline:boolean;
}

export abstract class PrimaryRenderPass {
  @LazyInject() halEditing:HalResourceEditingService;

  @LazyInject() states:States;

  @LazyInject() I18n!:I18nService;

  public draft:RenderDraft;

  private withTimeline = false;

  /** Resulting table body */
  public tableBody:DocumentFragment;

  /** Additional render pass that handles timeline rendering */
  public timeline:TimelineRenderPass|null = null;

  /** Additional render pass that handles table relation rendering */
  public relations:RelationsRenderPass;

  /** Additional render pass that handles table child relation rendering */
  public childRelations:ChildRelationsRenderPass;

  /** Additional render pass that handles drag'n'drop handle rendering */
  public dragDropHandle:DragDropHandleRenderPass;

  /** Additional render pass that handles highlighting of rows */
  public highlighting:HighlightingRenderPass;

  constructor(
public readonly injector:Injector,
    public workPackageTable:WorkPackageTable,
    public rowBuilder:SingleRowBuilder,
) {
  }

  /**
   * Execute the entire render pass, executing this pass and all subsequent registered passes
   * for timeline and relations.
   * @return {PrimaryRenderPass}
   */
  public render({ timeline }:RenderPassOptions):this {
    this.withTimeline = timeline;
    timeOutput('Primary render pass', () => {
      // Prepare and reset the render pass
      this.prepare();

      // Render into the table fragment
      this.doRender();

      // Post render
      this.postRender();
    });

    // Render subsequent passes
    // that may modify the structure of the table
    this.highlighting.render();

    timeOutput('Relations render pass', () => {
      this.relations.render();
      this.childRelations.render();
    });

    timeOutput('Drag handle render pass', () => {
      this.dragDropHandle.render();
    });

    // Synchronize the rows to timeline
    const timelinePass = this.timeline;
    if (timelinePass) {
      timeOutput('Timelines render pass', () => timelinePass.render());
    }

    return this;
  }

  public refresh(occurrence:RenderedOccurrence, workPackage:WorkPackageResource):HTMLTableRowElement|null {
    const oldRow = occurrence.element;
    if (!oldRow) {
      return null;
    }

    const replacement = this.refreshedRow(occurrence, workPackage, oldRow);
    if (replacement !== oldRow) {
      oldRow.replaceWith(replacement);
      replacement.dataset.occurrenceKey = occurrence.key;
    }

    return replacement;
  }

  private refreshedRow(
    occurrence:RenderedOccurrence,
    workPackage:WorkPackageResource,
    oldRow:HTMLTableRowElement,
  ):HTMLTableRowElement {
    switch (occurrence.renderType) {
      case 'relations':
        return this.relations.refreshRelationRow(occurrence, workPackage, oldRow);
      case 'child_relations':
        return this.childRelations.refreshRelationRow(occurrence, workPackage, oldRow);
      default:
        return this.rowBuilder.refreshRow(workPackage, oldRow);
    }
  }

  /**
   * Splice a row into the current render pass after the last row matching the given selector.
   */
  public spliceRow(row:HTMLTableRowElement, selector:string, occurrence:Omit<DraftOccurrence, 'element'>) {
    const matches = this.tableBody.querySelectorAll<HTMLTableRowElement>(selector);
    invariant(matches.length, `No matches found for selector: ${selector}`);

    const target = matches[matches.length - 1];
    const targetKey = target.dataset.occurrenceKey;
    invariant(targetKey, `Splice target matched by ${selector} carries no occurrence key`);

    target.parentNode!.insertBefore(row, target.nextSibling);
    row.dataset.occurrenceKey = occurrence.key;
    this.draft.spliceAfter(targetKey, { ...occurrence, element: row });
  }

  protected prepare() {
    this.timeline = this.withTimeline ? new TimelineRenderPass(this.injector, this.workPackageTable, this) : null;
    this.relations = new RelationsRenderPass(this.injector, this.workPackageTable, this);
    this.childRelations = new ChildRelationsRenderPass(this.injector, this.workPackageTable, this);
    this.dragDropHandle = new DragDropHandleRenderPass(this.injector, this.workPackageTable, this);
    this.highlighting = new HighlightingRenderPass(this.injector, this.workPackageTable, this);
    this.tableBody = document.createDocumentFragment();
    this.draft = this.workPackageTable.ledger.beginRender(this.withTimeline);
  }

  /**
   * The actual render function of this renderer.
   */
  protected abstract doRender():void;

  /**
   * Post render shared among all sub passes
   */
  protected postRender():void {
    if (this.draft.occurrences.length === 0 && this.workPackageTable.renderPlaceholderRow) {
      this.registerAppended(this.rowBuilder.placeholderRow, {
        key: placeholderOccurrenceKey(),
        classIdentifier: 'wp--placeholder-row',
        additionalClasses: [],
        workPackage: null,
        workPackageId: null,
        renderType: 'primary',
        hidden: false,
      });
    }
  }

  /**
   * Append a work package row to both containers
   * @param workPackage The work package, if the row belongs to one
   * @param row HTMLElement to append
   * @param rowClasses Additional classes to apply to the timeline row for mirroring purposes
   * @param hidden whether the row was rendered hidden
   */
  protected appendRow(
workPackage:WorkPackageResource,
    row:HTMLTableRowElement,
    additionalClasses:string[] = [],
    hidden = false,
) {
    this.registerAppended(row, {
      key: wpOccurrenceKey(workPackage.id!),
      classIdentifier: this.rowBuilder.classIdentifier(workPackage),
      additionalClasses,
      workPackage,
      workPackageId: workPackage.id!,
      renderType: 'primary',
      hidden,
    });
  }

  /**
   * Append a non-work package row to both containers
   * @param row HTMLElement to append
   * @param classIdentifer a unique identifier for the two rows (one each in table/timeline).
   * @param hidden whether the row was rendered hidden
   */
  protected appendNonWorkPackageRow(
    key:OccurrenceKey,
    row:HTMLTableRowElement,
    classIdentifer:string,
    additionalClasses:string[] = [],
    hidden = false,
  ) {
    row.classList.add(classIdentifer);
    this.registerAppended(row, {
      key,
      classIdentifier: classIdentifer,
      additionalClasses,
      workPackage: null,
      workPackageId: null,
      renderType: 'primary',
      hidden,
    });
  }

  protected registerAppended(row:HTMLTableRowElement, occurrence:Omit<DraftOccurrence, 'element'>) {
    this.tableBody.appendChild(row);
    row.dataset.occurrenceKey = occurrence.key;
    this.draft.append({ ...occurrence, element: row });
  }
}
