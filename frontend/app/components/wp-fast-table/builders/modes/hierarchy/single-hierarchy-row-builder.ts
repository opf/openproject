import {WorkPackageTable} from '../../../wp-fast-table';
import {WorkPackageTableRow} from '../../../wp-table.interfaces';
import {WorkPackageResourceInterface} from '../../../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableHierarchiesService} from '../../../state/wp-table-hierarchy.service';
import {$injectFields} from '../../../../angular/angular-injector-bridge.functions';
import {WorkPackageEditForm} from '../../../../wp-edit-form/work-package-edit-form';
import {
  collapsedGroupClass,
  hasChildrenInTable,
  hierarchyRootClass
} from '../../../helpers/wp-table-hierarchy-helpers';
import {UiStateLinkBuilder} from '../../ui-state-link-builder';
import {QueryColumn} from '../../../../wp-query/query-column';
import {SingleRowBuilder} from '../../rows/single-row-builder';
import {States} from '../../../../states.service';
import {WorkPackageChangeset} from '../../../../wp-edit-form/work-package-changeset';

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';
export const additionalHierarchyRowClassName =  'wp-table--hierarchy-aditional-row';

export class SingleHierarchyRowBuilder extends SingleRowBuilder {
  // Injected
  public wpTableHierarchies:WorkPackageTableHierarchiesService;
  public states:States;

  public text:{
    leaf:(level:number) => string;
    expanded:(level:number) => string;
    collapsed:(level:number) => string;
  };

  constructor(protected workPackageTable:WorkPackageTable) {
    super(workPackageTable);
    $injectFields(this, 'wpTableHierarchies', 'states');

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
  public refreshRow(workPackage:WorkPackageResourceInterface, changeset:WorkPackageChangeset, jRow:JQuery):JQuery {
    // Remove any old hierarchy
    const newRow = super.refreshRow(workPackage, changeset, jRow);
    newRow.find(`.wp-table--hierarchy-span`).remove();
    this.appendHierarchyIndicator(workPackage, newRow);

    return newRow;
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResourceInterface):[HTMLElement, boolean] {
    let [element, hidden] = super.buildEmpty(workPackage);
    const state = this.wpTableHierarchies.currentState;

    workPackage.ancestors.forEach((ancestor:WorkPackageResourceInterface) => {
      element.classList.add(`__hierarchy-group-${ancestor.id}`);

      if (state.collapsed[ancestor.id]) {
        hidden = true;
        element.classList.add(collapsedGroupClass(ancestor.id));
      }
    });

    element.classList.add(`__hierarchy-root-${workPackage.id}`);
    this.appendHierarchyIndicator(workPackage, jQuery(element));
    return [element, hidden];
  }

  /**
   * Append an additional ancestor row that is not yet loaded
   */
  public buildAncestorRow(ancestor:WorkPackageResourceInterface,
                          ancestorGroups:string[],
                          index:number):[HTMLElement, boolean] {

    const workPackage = this.states.workPackages.get(ancestor.id).value!;
    const [tr, hidden] = this.buildEmpty(workPackage);
    tr.classList.add(additionalHierarchyRowClassName)
    return [tr, hidden];
  }

  /**
   * Append to the row of hierarchy level <level> a hierarchy indicator.
   * @param workPackage
   * @param row
   * @param level
   */
  private appendHierarchyIndicator(workPackage:WorkPackageResourceInterface, jRow:JQuery, level?:number):void {
    const hierarchyElement = this.buildHierarchyIndicator(workPackage, jRow, level);

    jRow.find('td.subject')
      .addClass('-with-hierarchy')
      .prepend(hierarchyElement);
  }

  /**
   * Build the hierarchy indicator at the given indentation level.
   */
  private buildHierarchyIndicator(workPackage:WorkPackageResourceInterface, jRow:JQuery | null, index:number | null = null):HTMLElement {
    const level = index === null ? workPackage.ancestors.length : index;
    const hierarchyIndicator = document.createElement('span');
    const collapsed = this.wpTableHierarchies.collapsed(workPackage.id);
    const indicatorWidth = 25 + (20 * level) + 'px';
    hierarchyIndicator.classList.add(hierarchyCellClassName);
    hierarchyIndicator.style.width = indicatorWidth;

    if (hasChildrenInTable(workPackage, this.workPackageTable)) {
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

SingleHierarchyRowBuilder.$inject = ['states', 'I18n'];
