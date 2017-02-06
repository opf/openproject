import {GroupObject} from './wp-table.interfaces';
interface TablePaginationOptions {
  // Current page we're on
  page:number;
  // Number of elements per page
  perPage:number;
  // Available options for perPage
  perPageOptions:number[];
}

/**
 * Contains references to the current metadata returned from the API
 * accompanying a result set of work packages.
 */
export class WorkPackageTableMetadata {
  // Reference to an attribute that the results are grouped by
  public groupBy?:string;
  public groups:GroupObject[];

  // Total number of results
  public total:number;

  // Available links returned from collection resource
  public links:{ [name:string]: string };
  public bulkLinks:{ [name:string]: string };

  // Groupable columns
  public groupableColumns:api.ex.Column[];

  // Sums
  public totalSums:{[attribute:string]: any};

  // Export formats
  public exportFormats:api.ex.ExportFormat[];

  constructor(public json:api.ex.WorkPackagesMeta) {
    let meta = json.meta;

    // Grouping data
    this.groupBy = meta.query.groupBy;
    this.groups = json.resource.groups;
    this.groupableColumns = meta.groupable_columns;

    // Sums
    this.totalSums = json.resource.totalSums;

    // Links
    this.links = json._links;
    this.bulkLinks = json._bulk_links;
    this.exportFormats = meta.export_formats;

    // Pagination
    this.total = json.resource.total;
  }

  /**
   * Returns whether the current result is using a group by clause.
   */
  public get isGrouped():boolean {
    return !!this.groupBy;
  }
}
