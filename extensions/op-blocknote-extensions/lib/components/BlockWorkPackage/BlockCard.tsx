import { forwardRef, memo } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import type { BlockWpSize } from '../WorkPackage/types';
import type { TapActivationProps } from '../../utils/tapActivation';
import { BlockCardM, BlockCardL, BlockCardXL } from './BlockCards';

export interface BlockCardProps {
  workPackage:WorkPackage;
  size?:BlockWpSize;
  inDropdown?:boolean;
  linkTitle?:boolean;
  onActivation?:TapActivationProps;
}

// Memoized: rendered inside popovers that re-render on hover/selection, while
// the work package reference stays stable (cached by useWorkPackage).
export const BlockCard = memo(
  forwardRef<HTMLDivElement, BlockCardProps>(
    ({ workPackage, size = 'm', inDropdown, linkTitle, onActivation }, ref) => {
      const shared = { workPackage, inDropdown, linkTitle, onActivation, cardRef: ref };

      if (size === 'xl') return <BlockCardXL {...shared} />;
      if (size === 'l')  return <BlockCardL  {...shared} />;
      return <BlockCardM {...shared} />;
    }
  )
);

BlockCard.displayName = 'BlockCard';