import {Injector} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {SingleRowBuilder} from "core-components/wp-fast-table/builders/rows/single-row-builder";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {States} from "core-components/states.service";
import {
  collapsedGroupClass,
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';
export const additionalHierarchyRowClassName = 'wp-table--hierarchy-aditional-row';
export const hierarchyIndentation = 20;
export const hierarchyBaseIndentation = 25;

export class SingleHierarchyRowBuilder extends SingleRowBuilder {
  // Injected
  @InjectField() public wpTableHierarchies:WorkPackageViewHierarchiesService;
  @InjectField() public states:States;

  // Retain a map of hierarchy elements present in the table
  // with at least a visible child
  public parentsWithVisibleChildren:{ [id:string]:boolean };

  public text:{
    leaf:(level:number) => string;
    expanded:(level:number) => string;
    collapsed:(level:number) => string;
  };

  constructor(public readonly injector:Injector,
              protected workPackageTable:WorkPackageTable) {

    super(injector, workPackageTable);

    this.text = {
      leaf: (level:number) => this.I18n.t('js.work_packages.hierarchy.leaf', {level: level}),
      expanded: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_expanded',
        {level: level}),
      collapsed: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_collapsed',
        {level: level}),
    };
  }

  /**
   * Refresh a single row after structural changes.
   * Remembers and re-adds the hierarchy indicator if neccessary.
   */
  public refreshRow(workPackage:WorkPackageResource, jRow:JQuery):JQuery {
    // Remove any old hierarchy
    const newRow = super.refreshRow(workPackage, jRow);
    newRow.find(`.wp-table--hierarchy-span`).remove();
    this.appendHierarchyIndicator(workPackage, newRow);

    return newRow;
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):[HTMLTableRowElement, boolean] {
    let [element, _] = super.buildEmpty(workPackage);
    let [classes, hidden] = this.ancestorRowData(workPackage);
    element.classList.add(...classes);

    this.appendHierarchyIndicator(workPackage, jQuery(element));
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

    if (_.isArray(workPackage.ancestors)) {
      workPackage.ancestors.forEach((ancestor) => {
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
   * @param jRow jQuery row element
   * @param level Indentation level
   */
  private appendHierarchyIndicator(workPackage:WorkPackageResource, jRow:JQuery, level?:number):void {
    const hierarchyLevel = level === undefined || null ? workPackage.ancestors.length : level;
    const hierarchyElement = this.buildHierarchyIndicator(workPackage, jRow, hierarchyLevel);

    jRow.find('td.subject')
      .addClass('-with-hierarchy')
      .prepend(hierarchyElement);

    // Assure that the content is still visble when the hierarchy indentation is very large
    jRow.find('td.subject').css('minWidth', 125 + (hierarchyIndentation * hierarchyLevel) + 'px');
    jRow.find('td.subject .wp-table--cell-container')
      .css('width', 'calc(100% - ' + hierarchyBaseIndentation + 'px - ' + (hierarchyIndentation * hierarchyLevel) + 'px)');
  }

  /**
   * Build the hierarchy indicator at the given indentation level.
   */
  private buildHierarchyIndicator(workPackage:WorkPackageResource, jRow:JQuery|null, level:number):HTMLElement {
    const hierarchyIndicator = document.createElement('span');
    const collapsed = this.wpTableHierarchies.collapsed(workPackage.id!);
    const indicatorWidth = hierarchyBaseIndentation + (hierarchyIndentation * level) + 'px';
    hierarchyIndicator.classList.add(hierarchyCellClassName);
    hierarchyIndicator.style.width = indicatorWidth;
    hierarchyIndicator.dataset.indentation = indicatorWidth;

    if (this.parentsWithVisibleChildren[workPackage.id!]) {
      const className = collapsed ? indicatorCollapsedClass : '';
      hierarchyIndicator.innerHTML = `
            <a href tabindex="0" role="button" class="wp-table--hierarchy-indicator ${className}">
              <span class="wp-table--hierarchy-indicator-icon" aria-hidden="true"></span>
              <span class="wp-table--hierarchy-indicator-expanded hidden-for-sighted">${this.text.expanded(
        level)}</span>
              <span class="wp-table--hierarchy-indicator-collapsed hidden-for-sighted">${this.text.collapsed(
        level)}</span>
            </a>
        `;
    } else {
      hierarchyIndicator.innerHTML = `
            <span tabindex="0" class="wp-table--leaf-indicator">
              <span class="hidden-for-sighted">${this.text.leaf(level)}</span>
            </span>
        `;
    }

    return hierarchyIndicator;
  }

}
