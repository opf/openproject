import { useTranslation } from 'react-i18next';
import styled, { keyframes } from 'styled-components';

const rotate = keyframes`
  to { transform: rotate(360deg); }
`;

const SpinnerSvg = styled.svg.attrs({ className: 'op-bn-spinner' })`
  flex-shrink: 0;
  animation: ${rotate} 1s linear infinite;

  @media (prefers-reduced-motion: reduce) {
    animation-duration: 2s;
  }
`;

export const Spinner = ({ size = 16 }:{ size?:number }) => {
  const { t } = useTranslation();

  return (
    <SpinnerSvg
      role="img"
      aria-label={t('spinner.ariaLabel')}
      width={size}
      height={size}
      viewBox="0 0 16 16"
      fill="none"
    >
      <circle
        cx="8"
        cy="8"
        r="7"
        stroke="currentColor"
        strokeOpacity="0.25"
        strokeWidth="2"
        vectorEffect="non-scaling-stroke"
      />
      <path
        d="M15 8a7.002 7.002 0 0 0-7-7"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        vectorEffect="non-scaling-stroke"
      />
    </SpinnerSvg>
  );
};
