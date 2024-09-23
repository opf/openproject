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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  HostListener,
  Injector,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { filter } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageInlineCreateService,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { combineLatest, Subscription } from 'rxjs';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  inlineCreateCancelClassName,
  InlineCreateRowBuilder,
  inlineCreateRowClassName,
} from './inline-create-row-builder';
import { WorkPackageCreateService } from '../wp-new/wp-create.service';
import { WorkPackageTable } from '../wp-fast-table/wp-fast-table';
import { onClickOrEnter } from '../wp-fast-table/handlers/click-or-enter-handler';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';

@Component({
  selector: '[wpInlineCreate]',
  templateUrl: './wp-inline-create.component.html',
})
export class WorkPackageInlineCreateComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() colspan:number;

  @Input() table:WorkPackageTable;

  @Input() projectIdentifier:string;

  @Output() showing = new EventEmitter<boolean>();

  // inner state
  public canAdd = false;

  public canReference = false;

  // Inline create / reference row is active
  public mode:'inactive'|'create'|'reference' = 'inactive';

  public focus = false;

  public text = this.wpInlineCreate.buttonTexts;

  private currentWorkPackage:WorkPackageResource|null;

  private workPackageEditForm:EditForm|undefined;

  private editingSubscription:Subscription|undefined;

  private $element:JQuery;

  get isActive():boolean {
    return this.mode !== 'inactive';
  }

  constructor(public readonly injector:Injector,
    protected readonly elementRef:ElementRef,
    protected readonly schemaCache:SchemaCacheService,
    protected readonly I18n:I18nService,
    protected readonly querySpace:IsolatedQuerySpace,
    protected readonly cdRef:ChangeDetectorRef,
    protected readonly wpCreate:WorkPackageCreateService,
    protected readonly wpInlineCreate:WorkPackageInlineCreateService,
    protected readonly wpTableColumns:WorkPackageViewColumnsService,
    protected readonly wpTableFocus:WorkPackageViewFocusService,
    protected readonly halEditing:HalResourceEditingService,
    protected readonly authorisationService:AuthorisationService) {
    super();
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
  }

  ngAfterViewInit():void {
    combineLatest([
      this.wpInlineCreate.canAdd,
      this.wpInlineCreate.canReference,
    ])
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(([canAdd, canReference]) => {
        this.canAdd = canAdd;
        this.canReference = this.hasReferenceClass && canReference;
        this.cdRef.detectChanges();
        this.showing.emit(this.canAdd || this.canReference);
      });


    // Register callback on newly created work packages
    this.registerCreationCallback();

    // Watch on this scope when the columns change and refresh this row
    this.refreshOnColumnChanges();

    // Cancel edition of current new row
    this.registerCancelHandler();
  }

  /**
   * Reset the inline creation row on the cancel button,
   * which is dynamically inserted into the action row by the inline create renderer.
   */
  private registerCancelHandler() {
    this.$element.on('click keydown', `.${inlineCreateCancelClassName}`, (evt:JQuery.TriggeredEvent) => {
      onClickOrEnter(evt, () => {
        this.resetRow();
      });

      evt.stopImmediatePropagation();
      return false;
    });
  }

  /**
   * Since the table is refreshed imperatively whenever columns are changed,
   * we need to manually ensure the inline create row gets refreshed as well.
   */
  private refreshOnColumnChanges() {
    this.wpTableColumns
      .updates$()
      .pipe(
        filter(() => this.isActive), // Take only when row is inserted
        this.untilDestroyed(),
      )
      .subscribe(() => this.refreshRow());
  }

  /**
   * Listen to newly created work packages to detect whether the WP is the one we created,
   * and properly reset inline create in this case
   */
  private registerCreationCallback() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((wp:WorkPackageResource) => {
        if (this.currentWorkPackage && this.currentWorkPackage.__initialized_at === wp.__initialized_at) {
          // Remove row and focus
          this.resetRow();

          // Split view on the last inserted id if any
          if (!this.table.configuration.isEmbedded) {
            this.wpTableFocus.updateFocus(wp.id!);
          }

          // Notify inline create service
          this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id!);
        } else {
          // Remove current row
          this.wpCreate.cancelCreation();
          this.removeWorkPackageRow();
          this.showRow();
        }

        this.cdRef.detectChanges();
      });
  }

  public handleAddRowClick() {
    this.addWorkPackageRow();
    return false;
  }

  public handleReferenceClick() {
    this.mode = 'reference';
    return false;
  }

  public get referenceClass() {
    return this.wpInlineCreate.referenceComponentClass;
  }

  public get hasReferenceClass() {
    return !!this.referenceClass;
  }

  public addWorkPackageRow() {
    this.wpCreate
      .createOrContinueWorkPackage(this.projectIdentifier)
      .then((change:WorkPackageChangeset) => {
        const wp = this.currentWorkPackage = change.projectedResource;

        change
          .state
          ?.values$()
          .pipe(
            filter(() => !!this.currentWorkPackage),
          ).subscribe((form) => {
            if (!this.isActive) {
              this.insertRow(wp);
            } else {
              this.schemaCache.update(this.currentWorkPackage!, form.schema);
              this.refreshRow();
            }
          });
      });
  }

  private insertRow(wp:WorkPackageResource) {
    // Actually render the row
    const form = this.workPackageEditForm = this.renderInlineCreateRow(wp);

    setTimeout(() => {
      // Activate any required fields
      form.activateMissingFields();

      // Hide the button row
      this.hideRow();
    });
  }

  private refreshRow() {
    const builder = new InlineCreateRowBuilder(this.injector, this.table);
    const rowElement = this.$element.find(`.${inlineCreateRowClassName}`);

    if (rowElement.length && this.currentWorkPackage) {
      builder.refreshRow(this.currentWorkPackage, rowElement);
    }
  }

  /**
   * Actually render the row manually
   * in the same fashion as all rows in the table are rendered.
   *
   * @param wp Work package to be rendered
   * @returns The work package form of the row
   */
  private renderInlineCreateRow(wp:WorkPackageResource):EditForm {
    const builder = new InlineCreateRowBuilder(this.injector, this.table);
    const form = this.table.editing.startEditing(wp, builder.classIdentifier(wp));

    const [row] = builder.buildNew(wp, form);
    this.$element.append(row);

    return form;
  }

  /**
   * Reset the new work package row and refocus on the button
   */
  @HostListener('keydown.escape')
  public resetRow() {
    this.focus = true;
    this.removeWorkPackageRow();
    // Manually cancelled, show the row again
    setTimeout(() => {
      this.showRow();
      this.cdRef.detectChanges();
    }, 50);
  }

  public removeWorkPackageRow() {
    this.wpCreate.cancelCreation();
    this.currentWorkPackage = null;
    this.$element.find('.wp-row-new').remove();
    if (this.editingSubscription) {
      this.editingSubscription.unsubscribe();
    }
  }

  public showRow() {
    this.mode = 'inactive';
    this.cdRef.detectChanges();
  }

  public hideRow() {
    this.mode = 'create';
    this.cdRef.detectChanges();
  }
}
