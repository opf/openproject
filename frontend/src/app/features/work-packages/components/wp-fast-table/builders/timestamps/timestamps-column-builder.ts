import { Injector } from '@angular/core';
import {
  IWorkPackageTimestamp,
  WorkPackageResource,
} from 'core-app/features/hal/resources/work-package-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewTimestampsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timestamps.service';
import { tdClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/cell-builder';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';

export const timestampsCellName = 'wp-table--timestamps-cell-td';

export class TimestampsColumnBuilder {
  @InjectField() states:States;

  @InjectField() wpTableTimestamps:WorkPackageViewTimestampsService;

  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() schemaCache:SchemaCacheService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, timestampsCellName, column.id);
    td.dataset.columnId = column.id;

    const schema = this.schemaCache.of(workPackage);
    const timestamps = workPackage.attributesByTimestamp || [];

    // Nothing to render if we don't have a comparison
    if (timestamps.length <= 1) {
      return td;
    }

    const base = timestamps[0];
    const compare = timestamps[1];

    // Check if added
    const icon = this.changeIcon(base, compare, schema);
    if (icon) {
      td.appendChild(icon);
    }

    return td;
  }

  private changeIcon(
    base:IWorkPackageTimestamp,
    compare:IWorkPackageTimestamp,
    schema:ISchemaProxy,
  ):HTMLElement|null {
    if ((!base._meta.exists && compare._meta.exists) || (!base._meta.matchesFilters && compare._meta.matchesFilters)) {
      return opIconElement('icon-add', 'op-table-timestamps--icon-added');
    }

    if ((base._meta.exists && !compare._meta.exists) || (base._meta.matchesFilters && !compare._meta.matchesFilters)) {
      return opIconElement('icon-minus1', 'op-table-timestamps--icon-removed');
    }

    if (this.visibleAttributeChanged(base, schema)) {
      return opIconElement('icon-arrow-left-right', 'op-table-timestamps--icon-changed');
    }

    return null;
  }

  private visibleAttributeChanged(base:IWorkPackageTimestamp, schema:ISchemaProxy):boolean {
    return !!this
      .wpTableColumns
      .getColumns()
      .find((column) => {
        const name = schema.mappedName(column.id);
        return Object.prototype.hasOwnProperty.call(base, name) || Object.prototype.hasOwnProperty.call(base.$links, name);
      });
  }
}
