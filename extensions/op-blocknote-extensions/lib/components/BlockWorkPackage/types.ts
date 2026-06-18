import type { BlockWpSize } from '../WorkPackage/types';

export interface BlockWorkPackageProps {
  wpid?:number;
  size?:BlockWpSize;
  instanceId?:string;
  displayId?:string;
}
