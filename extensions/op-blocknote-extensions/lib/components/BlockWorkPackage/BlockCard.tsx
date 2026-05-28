import { forwardRef } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import type { BlockWpSize } from '../WorkPackage/types';
import { BlockCardM, BlockCardL, BlockCardXL } from './BlockCards';

export interface BlockCardProps {
  workPackage:WorkPackage;
  size?:BlockWpSize;
  inDropdown?:boolean;
  linkTitle?:boolean;
  onClick?:(e:React.MouseEvent<HTMLDivElement>) => void;
}

export const BlockCard = forwardRef<HTMLDivElement, BlockCardProps>(
  ({ workPackage, size = 'm', inDropdown, linkTitle, onClick }, ref) => {
    const shared = { workPackage, inDropdown, linkTitle, onClick, cardRef: ref };

    if (size === 'xl') return <BlockCardXL {...shared} />;
    if (size === 'l')  return <BlockCardL  {...shared} />;
    return <BlockCardM {...shared} />;
  }
);

BlockCard.displayName = 'BlockCard';