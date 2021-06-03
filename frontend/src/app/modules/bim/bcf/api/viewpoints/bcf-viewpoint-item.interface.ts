import { BcfViewpointInterface } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";

export interface BcfViewpointItem {
  /** The URL of the viewpoint, if persisted */
  href?:string|null;
  /** URL (persisted or data) to the snapshot */
  snapshotURL:string;
  /** The loaded snapshot, if exists */
  viewpoint?:BcfViewpointInterface;
}