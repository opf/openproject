import type { BlockWpSize } from '../WorkPackage/types';

export interface BlockWorkPackageProps {
  wpid?:number;
  initialized?:boolean;
  size?:BlockWpSize;
  instanceId?:string;
}
