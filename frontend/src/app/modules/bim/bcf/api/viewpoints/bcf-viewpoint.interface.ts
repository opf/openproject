/** Viewpoints use an interface to avoid (de)serialization of data we don't need */
export interface BcfViewpointInterface {
  guid:string;
  components:unknown;
  bitmaps:unknown[];
  orthogonal_camera?:unknown;
  perspective_camera?:unknown;
  snapshot:{ snapshot_type:string, snapshot_data:string };
}
