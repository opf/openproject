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
  Inject,
  Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit
} from '@angular/core';
import {AuthorisationService} from 'core-components/common/model-auth/model-auth.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {filter, takeUntil} from 'rxjs/operators';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {TableRowEditContext} from '../wp-edit-form/table-row-edit-context';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';
import {WorkPackageEditForm} from '../wp-edit-form/work-package-edit-form';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {WorkPackageFilterValues} from '../wp-edit-form/work-package-filter-values';
import {TimelineRowBuilder} from '../wp-fast-table/builders/timeline/timeline-row-builder';
import {onClickOrEnter} from '../wp-fast-table/handlers/click-or-enter-handler';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTable} from '../wp-fast-table/wp-fast-table';
import {WorkPackageCreateService} from '../wp-new/wp-create.service';
import {
  inlineCreateCancelClassName,
  InlineCreateRowBuilder,
  inlineCreateRowClassName
} from './inline-create-row-builder';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {FocusHelperToken, I18nToken} from 'core-app/angular4-transition-utils';

@Component({
  selector: '[wpInlineCreate]',
  template: require('!!raw-loader!./wp-inline-create.component.html'),
})
export class WorkPackageInlineCreateComponent implements OnInit, OnChanges, OnDestroy {

  @Input('wp-inline-create--table') table:WorkPackageTable;
  @Input('wp-inline-create--project-identifier') projectIdentifier:string;

  // inner state

  public isHidden:boolean = false;

  public focus:boolean = false;

  public text = {
    create: this.I18n.t('js.label_create_work_package')
  };

  private currentWorkPackage:WorkPackageResourceInterface | null;

  private workPackageEditForm:WorkPackageEditForm | undefined;

  private rowBuilder:InlineCreateRowBuilder;

  private timelineBuilder:TimelineRowBuilder;

  private $element:JQuery;

  constructor(readonly elementRef:ElementRef,
              readonly injector:Injector,
              @Inject(FocusHelperToken) readonly FocusHelper:any,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly tableState:TableState,
              readonly wpCacheService:WorkPackageCacheService,
              readonly wpEditing:WorkPackageEditingService,
              readonly wpCreate:WorkPackageCreateService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpTableFocus:WorkPackageTableFocusService,
              readonly authorisationService:AuthorisationService) {
  }

  ngOnDestroy() {
    // Compliance
  }

  ngOnInit() {
    this.$element = angular.element(this.elementRef.nativeElement);
  }

  ngOnChanges() {
    if (_.isNil(this.table)) {
      return;
    }

    this.rowBuilder = new InlineCreateRowBuilder(this.injector, this.table);
    this.timelineBuilder = new TimelineRowBuilder(this.injector, this.table);

    // Mirror the row height in timeline
    const container = jQuery('.wp-table-timeline--body');
    container.addClass('-inline-create-mirror');

    // Remove temporary rows on creation of new work package
    this.wpCreate.onNewWorkPackage()
      .takeUntil(componentDestroyed(this))
      .subscribe((wp:WorkPackageResourceInterface) => {
        if (this.currentWorkPackage && this.currentWorkPackage === wp) {
          // Add next row
          this.removeWorkPackageRow();
          this.addWorkPackageRow();

          // Focus on the last inserted id
          this.wpTableFocus.updateFocus(wp.id);
        } else {
          // Remove current row
          this.table.editing.stopEditing('new');
          this.removeWorkPackageRow();
          this.showRow();
        }
      });

    // Watch on this scope when the columns change and refresh this row
    this.tableState.columns.values$()
      .pipe(
        filter(() => this.isHidden), // Take only when row is inserted
        takeUntil(componentDestroyed(this))
      )
      .subscribe(() => {
      const rowElement = this.$element.find(`.${inlineCreateRowClassName}`);

      if (rowElement.length && this.currentWorkPackage) {
        this.rowBuilder.refreshRow(this.currentWorkPackage,
          this.workPackageEditForm!.changeset,
          rowElement);
      }
    });

    // Cancel edition of current new row
    this.$element.on('click keydown', `.${inlineCreateCancelClassName}`, (evt) => {
      onClickOrEnter(evt, () => {
        this.resetRow();
      });

      evt.stopImmediatePropagation();
      return false;
    });

    // Additionally, cancel on escape
    Mousetrap(this.$element[0]).bind('escape', () => {
      this.resetRow();
    });
  }

  public handleAddRowClick() {
    this.addWorkPackageRow();
    return false;
  }

  public addWorkPackageRow() {
    this.wpCreate.createNewWorkPackage(this.projectIdentifier).then((changeset:WorkPackageChangeset) => {
      if (!changeset) {
        throw 'No new work package was created';
      }

      const wp = this.currentWorkPackage = changeset.workPackage;

      // Apply filter values
      const filter = new WorkPackageFilterValues(changeset, this.wpTableFilters.current);
      filter.applyDefaultsFromFilters().then(() => {
        this.wpEditing.updateValue('new', changeset);
        this.wpCacheService.updateWorkPackage(this.currentWorkPackage!);

        // Set editing context to table
        const context = new TableRowEditContext(
          this.injector, wp.id, this.rowBuilder.classIdentifier(wp));
        this.workPackageEditForm = WorkPackageEditForm.createInContext(this.injector, context, wp, false);
        this.workPackageEditForm.changeset.clear();

        const row = this.rowBuilder.buildNew(wp, this.workPackageEditForm);
        this.$element.append(row);

        setTimeout(() => {
          this.workPackageEditForm!.activateMissingFields();
          this.hideRow();
        });
      });
    });
  }

  /**
   * Reset the new work package row and refocus on the button
   */
  public resetRow() {
    this.focus = true;
    this.removeWorkPackageRow();
    // Manually cancelled, show the row again
    setTimeout(() => {
      this.showRow();
    }, 50);
  }

  public removeWorkPackageRow() {
    this.currentWorkPackage = null;
    this.table.editing.stopEditing('new');
    this.wpCacheService.clearSome('new');
    this.$element.find('.wp-row-new').remove();
  }

  public showRow() {
    return this.isHidden = false;
  }

  public hideRow() {
    return this.isHidden = true;
  }

  public get colspan():number {
    return this.wpTableColumns.columnCount + 1;
  }

  public get isAllowed():boolean {
    return this.authorisationService.can('work_packages', 'createWorkPackage');
  }
}
