import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SingleRowBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/rows/single-row-builder';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { States } from 'core-app/core/states/states.service';
import {
  collapsedGroupClass,
  hierarchyGroupClass,
  hierarchyRootClass,
} from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';
export const additionalHierarchyRowClassName = 'wp-table--hierarchy-aditional-row';
export const hierarchyIndentation = 20;
export const hierarchyBaseIndentation = 25;

export class SingleHierarchyRowBuilder extends SingleRowBuilder {
  // Injected
  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() public states:States;

  // Retain a map of hierarchy elements present in the table
  // with at least a visible child
  public parentsWithVisibleChildren:Record<string, boolean>;

  public text:{
    leaf:(level:number) => string;
    expanded:(level:number) => string;
    collapsed:(level:number) => string;
  };

  constructor(public readonly injector:Injector,
    protected workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);

    this.text = {
      leaf: (level:number) => this.I18n.t('js.work_packages.hierarchy.leaf', { level }),
      expanded: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_expanded',
        { level }),
      collapsed: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_collapsed',
        { level }),
    };
  }

  /**
   * Refresh a single row after structural changes.
   * Remembers and re-adds the hierarchy indicator if necessary.
   */
  public refreshRow(workPackage:WorkPackageResource, row:HTMLTableRowElement) {
    // Remove any old hierarchy
    const newRow = super.refreshRow(workPackage, row);
    newRow.querySelector('.wp-table--hierarchy-span')?.remove();
    this.appendHierarchyIndicator(workPackage, newRow);

    return newRow;
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):[HTMLTableRowElement, boolean] {
    const [element, _] = super.buildEmpty(workPackage);
    const [classes, hidden] = this.ancestorRowData(workPackage);
    element.classList.add(...classes);

    this.appendHierarchyIndicator(workPackage, element);
    return [element, hidden];
  }

  /**
   * Returns a set of
   * @param workPackage
   */
  public ancestorRowData(workPackage:WorkPackageResource):[string[], boolean] {
    const state = this.wpTableHierarchies.current;
    const rowClasses:string[] = [];
    let hidden = false;

    if (this.parentsWithVisibleChildren[workPackage.id!]) {
      rowClasses.push(hierarchyRootClass(workPackage.id!));
    }

    const ancestors = workPackage.getAncestors();
    if (_.isArray(ancestors)) {
      ancestors.forEach((ancestor) => {
        rowClasses.push(hierarchyGroupClass(ancestor.id!));

        if (state.collapsed[ancestor.id!]) {
          hidden = true;
          rowClasses.push(collapsedGroupClass(ancestor.id!));
        }
      });
    }

    return [rowClasses, hidden];
  }

  /**
   * Append an additional ancestor row that is not yet loaded
   */
  public buildAncestorRow(ancestor:WorkPackageResource,
    ancestorGroups:string[],
    index:number):[HTMLTableRowElement, boolean] {
    const workPackage = this.states.workPackages.get(ancestor.id!).value!;
    const [tr, hidden] = this.buildEmpty(workPackage);
    tr.classList.add(additionalHierarchyRowClassName);
    return [tr, hidden];
  }

  /**
   * Append to the row of hierarchy level <level> a hierarchy indicator.
   * @param workPackage
   * @param row row element
   * @param level Indentation level
   */
  private appendHierarchyIndicator(workPackage:WorkPackageResource, row:HTMLTableRowElement, level?:number):void {
    const ancestors = workPackage.getAncestors();
    const hierarchyLevel = level === undefined || null ? ancestors.length : level;
    const hierarchyElement = this.buildHierarchyIndicator(workPackage, row, hierarchyLevel);

    const subjectCell = row.querySelector<HTMLTableCellElement>('td.subject');
    if (!subjectCell) return;

    subjectCell.classList.add('-with-hierarchy');
    subjectCell.prepend(hierarchyElement);

    // Assure that the content is still visible when the hierarchy indentation is very large
    subjectCell.style.minWidth = `${125 + (hierarchyIndentation * hierarchyLevel)}px`;
    const container = subjectCell.querySelector<HTMLElement>('.wp-table--cell-container');
    if (container) {
      container.style.width = `calc(100% - ${hierarchyBaseIndentation}px - ${hierarchyIndentation * hierarchyLevel}px)`;
    }
  }

  /**
   * Build the hierarchy indicator at the given indentation level.
   */
  private buildHierarchyIndicator(workPackage:WorkPackageResource, row:HTMLTableRowElement, level:number):HTMLElement {
    const hierarchyIndicator = document.createElement('span');
    const collapsed = this.wpTableHierarchies.collapsed(workPackage.id!);
    const indicatorWidth = `${hierarchyBaseIndentation + (hierarchyIndentation * level)}px`;
    hierarchyIndicator.classList.add(hierarchyCellClassName);
    hierarchyIndicator.style.width = indicatorWidth;
    hierarchyIndicator.dataset.indentation = indicatorWidth;

    if (this.parentsWithVisibleChildren[workPackage.id!]) {
      const className = collapsed ? indicatorCollapsedClass : '';
      hierarchyIndicator.innerHTML = `
            <a href tabindex="0" role="button" class="wp-table--hierarchy-indicator ${className}">
              <span class="wp-table--hierarchy-indicator-icon" aria-hidden="true"></span>
              <span class="wp-table--hierarchy-indicator-expanded sr-only">${this.text.expanded(
    level,
  )}</span>
              <span class="wp-table--hierarchy-indicator-collapsed sr-only">${this.text.collapsed(
    level,
  )}</span>
            </a>
        `;
    } else {
      hierarchyIndicator.innerHTML = `
            <span tabindex="0" class="wp-table--leaf-indicator">
              <span class="sr-only">${this.text.leaf(level)}</span>
            </span>
        `;
    }

    return hierarchyIndicator;
  }
}
