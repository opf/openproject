export interface RenderedWorkPackage {

  /** container-unique class name for the rendered work package */
  classIdentifier:string;

  /** The rendered work package or null if the item at this index is not a work package
   * (group header for tables, e.g,) */
  workPackageId:string|null;

  /** Whether this item is being hidden due to some condition */
  hidden:boolean;
}
