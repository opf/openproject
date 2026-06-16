import { Injector } from '@angular/core';
import { combineLatest } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import {
  TypeQuickFilterStateService,
} from 'core-app/features/work-packages/components/filters/type-quick-filter/type-quick-filter-state.service';
import {
  WorkPackageViewHierarchiesService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';

export class TypeFilterTransformer {
  @InjectField() typeQuickFilterState:TypeQuickFilterStateService;

  @InjectField() querySpace:IsolatedQuerySpace;

  @InjectField() states:States;

  @InjectField() wpTableHierarchies:WorkPackageViewHierarchiesService;

  private lastSelectedTypeHrefs:Set<string> = new Set();

  constructor(public readonly injector:Injector,
    _table:WorkPackageTable) {
    combineLatest([
      this.typeQuickFilterState.selectedTypeHrefs$,
      this.querySpace.tableRendered.values$(),
    ])
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe(([selectedTypeHrefs]) => {
        const filterJustChanged = !areSetsEqual(selectedTypeHrefs, this.lastSelectedTypeHrefs);
        this.lastSelectedTypeHrefs = new Set(selectedTypeHrefs);
        this.applyTypeVisibility(selectedTypeHrefs, filterJustChanged);
      });
  }

  private applyTypeVisibility(selectedTypeHrefs:Set<string>, filterJustChanged:boolean):void {
    const rendered = this.querySpace.tableRendered.value;
    if (!rendered) return;

    const filterActive = selectedTypeHrefs.size > 0;

    if (!filterActive) {
      rendered.forEach((row) => {
        if (!row.workPackageId) return;
        const tr = document.querySelector(`[data-work-package-id="${row.workPackageId}"]`) as HTMLElement|null;
        if (tr) tr.style.display = '';
      });
      return;
    }

    // Build wpId → typeHref map for all WPs in the current view
    const renderedTypeMap = new Map<string, string>();
    rendered.forEach((row) => {
      if (!row.workPackageId) return;
      const wp = this.states.workPackages.get(row.workPackageId).value;
      const typeHref = (wp?.type as { href?:string }|undefined)?.href;
      if (typeHref) renderedTypeMap.set(row.workPackageId, typeHref);
    });

    // On filter change only: expand collapsed ancestors of matching WPs so they become
    // genuinely visible (not hidden by CSS collapse class). Skipped on plain table re-renders
    // so that manual collapse by the user is respected (filterJustChanged = false).
    if (filterJustChanged) {
      let expandedAny = false;
      rendered.forEach((row) => {
        if (!row.workPackageId) return;
        const typeHref = renderedTypeMap.get(row.workPackageId);
        if (!typeHref || !selectedTypeHrefs.has(typeHref)) return;
        const wp = this.states.workPackages.get(row.workPackageId).value;
        if (!wp) return;
        wp.getAncestors().forEach((a) => {
          const id = (a as { id?:string|number }).id?.toString();
          if (id && this.wpTableHierarchies.collapsed(id)) {
            this.wpTableHierarchies.expand(id);
            expandedAny = true;
          }
        });
      });
      if (expandedAny) {
        // expand() → HierarchyTransformer → tableRendered re-emits → fires again with
        // filterJustChanged=false → applies display styles on the now-expanded table
        return;
      }
      // No expansions needed — fall through to apply display styles immediately
    }

    rendered.forEach((row) => {
      const { workPackageId } = row;
      if (!workPackageId) return;

      const wp = this.states.workPackages.get(workPackageId).value;
      if (!wp) return;

      const tr = document.querySelector(`[data-work-package-id="${workPackageId}"]`) as HTMLElement|null;
      if (!tr) return;

      // Show if own type matches
      const typeHref = renderedTypeMap.get(workPackageId);
      if (typeHref && selectedTypeHrefs.has(typeHref)) {
        tr.style.display = '';
        return;
      }

      // Show if any rendered ancestor's type matches (descendant of virtual root)
      const ancestors = wp.getAncestors();
      const hasMatchingAncestor = ancestors.some((a) => {
        const id = (a as { id?:string|number }).id?.toString();
        if (!id) return false;
        const aTypeHref = renderedTypeMap.get(id);
        return !!aTypeHref && selectedTypeHrefs.has(aTypeHref);
      });

      tr.style.display = hasMatchingAncestor ? '' : 'none';
    });
  }
}

function areSetsEqual(a:Set<string>, b:Set<string>):boolean {
  if (a.size !== b.size) return false;
  for (const val of a) {
    if (!b.has(val)) return false;
  }
  return true;
}
