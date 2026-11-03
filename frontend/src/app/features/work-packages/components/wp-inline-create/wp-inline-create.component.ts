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

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Injector, input, output, inject, DestroyRef, signal, computed, effect, untracked } from '@angular/core';
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
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  inlineCreateCancelClassName,
  InlineCreateRowBuilder,
  inlineCreateRowClassName,
} from './inline-create-row-builder';
import { WorkPackageCreateService } from '../wp-new/wp-create.service';
import { inlineCreateRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';
import { WorkPackageTable } from '../wp-fast-table/wp-fast-table';
import { onClickOrEnter } from '../wp-fast-table/handlers/click-or-enter-handler';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { delegate, DelegateEvent } from '@knowledgecode/delegate';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[wpInlineCreate]',
  templateUrl: './wp-inline-create.component.html',
  standalone: false,
  host: {
    '(keydown.escape)': 'cancelOnEscape($event)',
  },
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageInlineCreateComponent implements AfterViewInit {
  readonly injector = inject(Injector);
  protected readonly elementRef = inject<ElementRef<HTMLTableSectionElement>>(ElementRef);
  protected readonly schemaCache = inject(SchemaCacheService);
  protected readonly I18n = inject(I18nService);
  protected readonly querySpace = inject(IsolatedQuerySpace);
  protected readonly cdRef = inject(ChangeDetectorRef);
  protected readonly wpCreate = inject(WorkPackageCreateService);
  protected readonly wpInlineCreate = inject(WorkPackageInlineCreateService);
  protected readonly wpTableColumns = inject(WorkPackageViewColumnsService);
  protected readonly wpTableFocus = inject(WorkPackageViewFocusService);
  protected readonly halEditing = inject(HalResourceEditingService);
  protected readonly authorisationService = inject(AuthorisationService);

  readonly colspan = input.required<number>();

  readonly table = input.required<WorkPackageTable>();

  readonly projectIdentifier = input<string>();

  readonly showing = output<boolean>();

  private readonly destroyRef = inject(DestroyRef);

  private readonly viewReady = signal(false);

  private readonly permissions = toSignal(
    combineLatest({ canAdd: this.wpInlineCreate.canAdd, canReference: this.wpInlineCreate.canReference }),
    { initialValue: { canAdd: false, canReference: false } },
  );

  readonly canAdd = computed(() => this.permissions().canAdd);

  readonly canReference = computed(() => this.hasReferenceClass && this.permissions().canReference);

  private lastShowing?:boolean;

  private creationRequest = 0;

  private activationTimer?:ReturnType<typeof setTimeout>;

  private resetTimer?:ReturnType<typeof setTimeout>;

  // Inline create / reference row is active
  private readonly modeValue = signal<'inactive'|'create'|'reference'>('inactive');

  readonly mode = this.modeValue.asReadonly();

  readonly isActive = computed(() => this.mode() !== 'inactive');

  public focus = false;

  public focusTarget:'create'|'reference' = 'create';

  public text = this.wpInlineCreate.buttonTexts;

  private currentWorkPackage:WorkPackageResource|null;

  private workPackageEditForm:EditForm|undefined;

  private editingSubscription:Subscription|undefined;

  private readonly element = this.elementRef.nativeElement;

  constructor() {
    effect((onCleanup) => {
      this.table();
      onCleanup(() => {
        this.invalidateCreation();
        this.currentWorkPackage = null;
        this.workPackageEditForm = undefined;
        this.modeValue.set('inactive');
        this.element.querySelector('.wp-row-new')?.remove();
      });
    });

    effect(() => {
      if (!this.viewReady()) return;
      this.table();
      this.colspan();
      const canAdd = this.canAdd();
      const canReference = this.canReference();
      const showing = canAdd || canReference;
      untracked(() => {
        this.mutateRow(() => {
          this.cdRef.detectChanges();
        });
        if (this.lastShowing !== showing) {
          this.lastShowing = showing;
          this.showing.emit(showing);
        }
      });
    });
  }

  ngAfterViewInit():void {
    this.viewReady.set(true);

    // Register callback on newly created work packages
    this.registerCreationCallback();

    this.wpTableColumns.updates$()
      .pipe(takeUntilDestroyed(this.destroyRef), filter(() => this.isActive()))
      .subscribe(() => untracked(() => this.refreshRow()));

    // Cancel edition of current new row
    this.registerCancelHandler();
  }

  /**
   * Reset the inline creation row on the cancel button,
   * which is dynamically inserted into the action row by the inline create renderer.
   */
  private registerCancelHandler() {
    const handler = (evt:DelegateEvent) => {
      onClickOrEnter(evt.originalEvent, () => {
        evt.preventDefault();
        this.resetRow();
      });

      evt.stopImmediatePropagation();
      return false;
    };

    delegate(this.element)
      .on('click', `.${inlineCreateCancelClassName}`, handler)
      .on('keydown', `.${inlineCreateCancelClassName}`, handler);
  }

  /**
   * Listen to newly created work packages to detect whether the WP is the one we created,
   * and properly reset inline create in this case
   */
  private registerCreationCallback() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((wp:WorkPackageResource) => {
        if (this.table().destroyed) return;
        if (this.currentWorkPackage?.__initialized_at === wp.__initialized_at) {
          // Remove row and focus
          this.resetRow();

          this.table().keyboardNavigation.rememberWorkPackageAfterRender(wp.id!);

          // Split view on the last inserted id if any
          if (!this.table().configuration.isEmbedded) {
            this.wpTableFocus.initializeSelectionAndFocus(wp.id!);
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
    this.focusTarget = 'create';
    this.addWorkPackageRow();
    return false;
  }

  public handleReferenceClick() {
    this.focusTarget = 'reference';
    this.modeValue.set('reference');
    this.mutateRow(() => this.cdRef.detectChanges());
    return false;
  }

  public get referenceClass() {
    return this.wpInlineCreate.referenceComponentClass;
  }

  public get hasReferenceClass() {
    return !!this.referenceClass;
  }

  public addWorkPackageRow() {
    this.invalidateCreation();
    const request = this.creationRequest;
    const table = this.table();
    if (table.destroyed || this.destroyRef.destroyed) return;
    void this.wpCreate
      .createOrContinueWorkPackage(this.projectIdentifier())
      .then((change:WorkPackageChangeset) => {
        if (!this.isCurrentCreation(request, table)) return;
        const wp = this.currentWorkPackage = change.projectedResource;

        this.editingSubscription = change.state?.values$()
          .pipe(
            takeUntilDestroyed(this.destroyRef),
            takeUntilDestroyed(table.destroyRef),
            filter(() => this.isCurrentCreation(request, table) && !!this.currentWorkPackage),
          )
          .subscribe((form) => {
            if (!this.isActive) {
              this.insertRow(wp, request, table);
            } else {
              this.schemaCache.update(this.currentWorkPackage!, form.schema);
              this.refreshRow();
            }
          });
      });
  }

  private insertRow(wp:WorkPackageResource, request:number, table:WorkPackageTable) {
    this.workPackageEditForm = this.renderInlineCreateRow(wp);
    const form = this.workPackageEditForm;

    this.activationTimer = setTimeout(() => {
      if (!this.isCurrentCreation(request, table)) return;
      void form.activateMissingFields().then((activeFields) => {
        if (this.isCurrentCreation(request, table) && activeFields.length === 0) {
          void form.submit();
        }
      });
      this.hideRow();
    });
  }

  private isCurrentCreation(request:number, table:WorkPackageTable):boolean {
    return request === this.creationRequest && !this.destroyRef.destroyed
      && !table.destroyed && this.table() === table;
  }

  private invalidateCreation():void {
    this.creationRequest += 1;
    this.editingSubscription?.unsubscribe();
    this.editingSubscription = undefined;
    clearTimeout(this.activationTimer);
    clearTimeout(this.resetTimer);
  }

  private refreshRow() {
    const builder = new InlineCreateRowBuilder(this.injector, this.table());
    const rowElement = this.element.querySelector<HTMLTableRowElement>(`.${inlineCreateRowClassName}`);

    if (rowElement && this.currentWorkPackage) {
      this.mutateRow(() => builder.refreshRow(this.currentWorkPackage!, rowElement));
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
    const builder = new InlineCreateRowBuilder(this.injector, this.table());
    const form = this.table().editing.startEditing(wp, builder.classIdentifier(wp));

    const [row] = builder.buildNew(wp, form);
    this.mutateRow(() => this.element.append(row));

    return form;
  }

  public cancelOnEscape(event:KeyboardEvent) {
    if (this.mode() === 'inactive' || event.defaultPrevented) {
      return;
    }

    event.preventDefault();
    this.resetRow();
  }

  /**
   * Reset the new work package row and refocus on the button
   */
  public resetRow() {
    this.focus = true;
    this.removeWorkPackageRow();
    // Manually cancelled, show the row again
    const request = this.creationRequest;
    const table = this.table();
    this.resetTimer = setTimeout(() => {
      if (!this.isCurrentCreation(request, table)) return;
      this.showRow();
      this.cdRef.detectChanges();
    }, 50);
  }

  public removeWorkPackageRow() {
    this.invalidateCreation();
    this.wpCreate.cancelCreation();
    this.currentWorkPackage = null;
    this.mutateRow(() => this.element.querySelector('.wp-row-new')?.remove());
  }

  public showRow() {
    this.modeValue.set('inactive');
    this.mutateRow(() => this.cdRef.detectChanges());
    this.focus = false;
  }

  public hideRow() {
    this.modeValue.set('create');
    this.mutateRow(() => this.cdRef.detectChanges());
  }

  private mutateRow(change:() => void):void {
    const table = this.table();
    if (table.destroyed || this.destroyRef.destroyed) return;
    untracked(() => table.mutate(new Set([inlineCreateRowKey]), change));
  }
}
