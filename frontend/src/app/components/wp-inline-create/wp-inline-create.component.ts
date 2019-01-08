// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {
  Component,
  ElementRef,
  HostListener,
  Inject,
  Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit
} from '@angular/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {filter} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';
import {WorkPackageEditForm} from '../wp-edit-form/work-package-edit-form';
import {TimelineRowBuilder} from '../wp-fast-table/builders/timeline/timeline-row-builder';
import {onClickOrEnter} from '../wp-fast-table/handlers/click-or-enter-handler';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTable} from '../wp-fast-table/wp-fast-table';
import {WorkPackageCreateService} from '../wp-new/wp-create.service';
import {
  inlineCreateCancelClassName,
  InlineCreateRowBuilder,
  inlineCreateRowClassName
} from './inline-create-row-builder';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {CurrentUserService} from "core-components/user/current-user.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {Subscription} from 'rxjs';

@Component({
  selector: '[wpInlineCreate]',
  templateUrl: './wp-inline-create.component.html'
})
export class WorkPackageInlineCreateComponent implements OnInit, OnChanges, OnDestroy {

  @Input('wp-inline-create--table') table:WorkPackageTable;
  @Input('wp-inline-create--project-identifier') projectIdentifier:string;

  // inner state

  // Inline create / reference row is active
  public mode:'inactive'|'create'|'reference' = 'inactive';

  public focus:boolean = false;

  public text = this.wpInlineCreate.buttonTexts;

  private currentWorkPackage:WorkPackageResource | null;

  private workPackageEditForm:WorkPackageEditForm | undefined;

  private rowBuilder:InlineCreateRowBuilder;

  private timelineBuilder:TimelineRowBuilder;
  private editingSubscription:Subscription|undefined;

  private $element:JQuery;

  constructor(public readonly injector:Injector,
              protected readonly elementRef:ElementRef,
              protected readonly FocusHelper:FocusHelperService,
              protected readonly I18n:I18nService,
              protected readonly tableState:TableState,
              protected readonly currentUser:CurrentUserService,
              @Inject(IWorkPackageCreateServiceToken) protected readonly wpCreate:WorkPackageCreateService,
              protected readonly wpInlineCreate:WorkPackageInlineCreateService,
              protected readonly wpTableColumns:WorkPackageTableColumnsService,
              protected readonly wpTableFocus:WorkPackageTableFocusService,
              protected readonly authorisationService:AuthorisationService) {
  }

  ngOnDestroy() {
    // Compliance
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
  }

  get isActive():boolean {
    return this.mode !== 'inactive';
  }

  ngOnChanges() {
    if (_.isNil(this.table)) {
      return;
    }

    this.rowBuilder = new InlineCreateRowBuilder(this.injector, this.table);
    this.timelineBuilder = new TimelineRowBuilder(this.injector, this.table);

    // Mirror the row height in timeline
    const container = jQuery(this.table.timelineBody);
    container.addClass('-inline-create-mirror');

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
    this.$element.on('click keydown', `.${inlineCreateCancelClassName}`, (evt:JQueryEventObject) => {
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
    this.tableState.columns
      .values$()
      .pipe(
        filter(() => this.isActive), // Take only when row is inserted
        untilComponentDestroyed(this),
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
      .pipe(untilComponentDestroyed(this))
      .subscribe((wp:WorkPackageResource) => {
        if (this.currentWorkPackage && this.currentWorkPackage.__initialized_at === wp.__initialized_at) {
          // Remove row and focus
          this.resetRow();

          // Split view on the last inserted id if any
          if (!this.table.configuration.isEmbedded) {
            this.wpTableFocus.updateFocus(wp.id);
          }

          // Notify inline create service
          this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id);
        } else {
          // Remove current row
          this.wpCreate.cancelCreation();
          this.removeWorkPackageRow();
          this.showRow();
        }
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
      .then((changeset:WorkPackageChangeset) => {

      const wp = this.currentWorkPackage = changeset.workPackage;

      this.editingSubscription = this
        .wpCreate
        .changesetUpdates$()
        .pipe(
          filter((cs) => !!this.currentWorkPackage && !!cs.form),
        ).subscribe((form) => {
          if (!this.isActive) {
            this.insertRow(wp);
          } else {
            this.currentWorkPackage!.overriddenSchema = form!.schema;
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
    const rowElement = this.$element.find(`.${inlineCreateRowClassName}`);

    if (rowElement.length && this.currentWorkPackage) {
      this.rowBuilder.refreshRow(this.currentWorkPackage, rowElement);
    }
  }

  /**
   * Actually render the row manually
   * in the same fashion as all rows in the table are rendered.
   *
   * @param wp Work package to be rendered
   * @returns The work package form of the row
   */
  private renderInlineCreateRow(wp:WorkPackageResource):WorkPackageEditForm {
    const form = this.table.editing.startEditing(wp, this.rowBuilder.classIdentifier(wp));

    const [row, ] = this.rowBuilder.buildNew(wp, form);
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
  }

  public hideRow() {
    this.mode = 'create';
  }

  public get colspan():number {
    return this.wpTableColumns.columnCount + 1;
  }

  public get canReference():boolean {
    return this.hasReferenceClass && this.wpInlineCreate.canReference;
  }

  public get canAdd():boolean {
    return this.wpInlineCreate.canAdd;
  }
}
