import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { formatWorkPackageId } from '../../utils/id';
import { OptionsPopover, type SizeGroup } from '../Shared/OptionsMenu';
import type { BlockWpSize, InlineWpSize } from './types';

const INLINE_SIZE_OPTIONS:InlineWpSize[] = ['xxs', 'xs', 's'];
const BLOCK_SIZE_OPTIONS:BlockWpSize[] = ['m'];

export interface WpOptionsProps {
  wp?:WorkPackage;
  displayId?:string;
  currentSize?:InlineWpSize;
  currentBlockSize?:BlockWpSize;
  anchorEl?:HTMLElement | null;
  autoFocus?:boolean;
  onClose:() => void;
  onRestoreFocus?:() => void;
  onResize?:(size:InlineWpSize) => void;
  onRemove?:() => void;
  onConvertToBlock?:(size:BlockWpSize) => void;
  onConvertToInline?:(size:InlineWpSize) => void;
  onResizeBlock?:(size:BlockWpSize) => void;
}

export const WpOptionsPopover = ({
  wp,
  displayId,
  currentSize,
  currentBlockSize,
  onResize,
  onConvertToBlock,
  onConvertToInline,
  onResizeBlock,
  ...popoverProps
}:WpOptionsProps) => {
  const { t } = useTranslation();

  const isBlock = currentSize === undefined;
  const openId = wp?.displayId ?? displayId;
  const activeSize = isBlock ? (currentBlockSize ?? 'm') : currentSize;

  const sizeOption = (size:InlineWpSize | BlockWpSize, pick:() => void) => ({
    key: size,
    label: t(`sizes.${size}.label`),
    description: t(`sizes.${size}.desc`),
    pick,
  });

  const sizeGroups:SizeGroup[] = [
    {
      label: t('options.inlineSizeLabel'),
      options: INLINE_SIZE_OPTIONS.map((size) =>
        sizeOption(size, () => (isBlock ? onConvertToInline?.(size) : onResize?.(size)))),
    },
    {
      label: t('options.blockSizeLabel'),
      options: BLOCK_SIZE_OPTIONS.map((size) =>
        sizeOption(size, () => (isBlock ? onResizeBlock?.(size) : onConvertToBlock?.(size)))),
    },
  ];

  return (
    <OptionsPopover
      {...popoverProps}
      ariaLabel={openId ? t('options.menuAriaLabel', { id: formatWorkPackageId(openId) }) : undefined}
      openId={openId}
      activeSize={activeSize}
      sizeLabel={t(`sizes.${activeSize}.label`)}
      sizeGroups={sizeGroups}
      removeAriaLabel={t('options.removeAriaLabel')}
    />
  );
};
