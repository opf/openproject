import { forwardRef, memo } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import type { BlockWpSize } from '../WorkPackage/types';
import type { TapActivationProps } from '../../utils/tapActivation';
import type { MenuButtonProps } from '../../utils/a11y';
import { BlockCardM, BlockCardL, BlockCardXL } from './BlockCards';

export interface BlockCardProps {
  workPackage:WorkPackage;
  size?:BlockWpSize;
  inDropdown?:boolean;
  linkTitle?:boolean;
  onActivation?:TapActivationProps;
  menuButton?:MenuButtonProps;
}

// Memoized: rendered inside popovers that re-render on hover/selection, while
// the work package reference stays stable (cached by useWorkPackage).
export const BlockCard = memo(
  forwardRef<HTMLDivElement, BlockCardProps>(
    ({ workPackage, size = 'm', inDropdown, linkTitle, onActivation, menuButton }, ref) => {
      const shared = { workPackage, inDropdown, linkTitle, onActivation, menuButton, cardRef: ref };

      if (size === 'xl') return <BlockCardXL {...shared} />;
      if (size === 'l')  return <BlockCardL  {...shared} />;
      return <BlockCardM {...shared} />;
    }
  )
);

BlockCard.displayName = 'BlockCard';