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
  ElementRef, HostListener,
  Inject,
  Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit
} from '@angular/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {filter, takeUntil} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
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
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {IWorkPackageEditingServiceToken} from "../wp-edit-form/work-package-editing.service.interface";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";

@Component({
  selector: '[wpInlineCreate]',
  templateUrl: './wp-inline-create.component.html'
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

  private currentWorkPackage:WorkPackageResource | null;

  private workPackageEditForm:WorkPackageEditForm | undefined;

  private rowBuilder:InlineCreateRowBuilder;

  private timelineBuilder:TimelineRowBuilder;

  private $element:JQuery;

  constructor(readonly elementRef:ElementRef,
              readonly injector:Injector,
              readonly FocusHelper:FocusHelperService,
              readonly I18n:I18nService,
              readonly tableState:TableState,
              readonly wpCacheService:WorkPackageCacheService,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              @Inject(IWorkPackageCreateServiceToken) protected wpCreate:WorkPackageCreateService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpTableFocus:WorkPackageTableFocusService,
              readonly authorisationService:AuthorisationService) {
  }

  ngOnDestroy() {
    // Compliance
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
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

    // Remove temporary rows on creation of new work package
    this.wpCreate.onNewWorkPackage()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((wp:WorkPackageResource) => {
        if (this.currentWorkPackage && this.currentWorkPackage === wp) {
          // Remove row and focus
          this.resetRow();

          // Split view on the last inserted id if any
          if (!this.table.configuration.isEmbedded) {
            this.wpTableFocus.updateFocus(wp.id);
          }
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
        this.rowBuilder.refreshRow(this.currentWorkPackage, rowElement);
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
      const filter = new WorkPackageFilterValues(changeset, this.tableState.query.value!.filters);
      filter.applyDefaultsFromFilters().then(() => {
        this.wpEditing.updateValue('new', changeset);
        this.wpCacheService.updateWorkPackage(this.currentWorkPackage!);

        // Set editing context to table
        const context = new TableRowEditContext(
          this.table,
          this.injector,
          wp.id,
          this.rowBuilder.classIdentifier(wp)
        );
        
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
    return this.authorisationService.can('work_packages', 'createWorkPackage') ||
      this.authorisationService.can('work_package', 'addChild');
  }
}
