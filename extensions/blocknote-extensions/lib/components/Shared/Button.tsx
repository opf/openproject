import styled, { css } from 'styled-components';

const primaryStyles = css`
  --op-button-bg: var(--button-primary-bgColor-rest, #1f883d);
  --op-button-bg-hover: var(--button-primary-bgColor-hover, #1c8139);
  --op-button-border: var(--op-button-bg);
  --op-button-border-hover: var(--op-button-bg-hover);
  --op-button-text: var(--button-primary-fgColor-rest, #ffffff);
  --op-button-bg-disabled: var(--button-primary-bgColor-disabled, #95d8a6);
  --op-button-text-disabled: var(--button-primary-fgColor-disabled, #ffffffcc);

  [data-color-scheme="dark"] & {
    --op-button-bg: var(--button-primary-bgColor-rest, #238636);
    --op-button-bg-hover: var(--button-primary-bgColor-hover, #29903b);
    --op-button-bg-disabled: var(--button-primary-bgColor-disabled, #105823);
    --op-button-text-disabled: var(--button-primary-fgColor-disabled, #ffffff66);
  }

  &:disabled {
    border-color: var(--op-button-bg-disabled);
    background: var(--op-button-bg-disabled);
    color: var(--op-button-text-disabled);
  }
`;

const defaultStyles = css`
  --op-button-bg: var(--button-default-bgColor-rest, #f6f8fa);
  --op-button-bg-hover: var(--button-default-bgColor-hover, #eff2f5);
  --op-button-border: var(--button-default-borderColor-rest, #d1d9e0);
  --op-button-border-hover: var(--op-button-border);
  --op-button-text: var(--fgColor-default, #1f2328);

  [data-color-scheme="dark"] & {
    --op-button-bg: var(--button-default-bgColor-rest, #212830);
    --op-button-bg-hover: var(--button-default-bgColor-hover, #262c36);
    --op-button-border: var(--button-default-borderColor-rest, #3d444d);
    --op-button-text: var(--fgColor-default, #f0f6fc);
  }
`;

export const Button = styled.button<{ $primary?:boolean }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 28px;
  padding: 0 var(--spacer-l);
  border: 1px solid var(--op-button-border);
  border-radius: 6px;
  background: var(--op-button-bg);
  color: var(--op-button-text);
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
  cursor: pointer;

  &:hover:not(:disabled) {
    border-color: var(--op-button-border-hover);
    background: var(--op-button-bg-hover);
  }

  &:disabled {
    cursor: not-allowed;
  }

  ${({ $primary }) => ($primary ? primaryStyles : defaultStyles)}
`;
