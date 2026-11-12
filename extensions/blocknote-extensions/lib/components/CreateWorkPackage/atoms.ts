import styled, { createGlobalStyle, css, keyframes } from 'styled-components';
import flatpickrStyles from 'flatpickr/dist/flatpickr.css?inline';
import {
  borderColor,
  controlBorderColor,
  controlStyles,
  radius,
  surfaceColor,
  textColor,
} from '../Shared/atoms';

export const Form = styled.form`
  display: flex;
  flex: 1;
  flex-direction: column;
  min-height: 0;
`;

export const FooterStatus = styled.div`
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  margin-right: auto;
  font-size: 0.85em;
  color: var(--op-create-wp-muted);
`;

export const Divider = styled.hr`
  && {
    margin: 0 0 var(--spacer-xl);
    border: none;
    border-top: 1px solid ${borderColor};
  }
`;

export const FieldError = styled.div.attrs({ role: 'alert' })`
  margin-top: var(--spacer-s);
  font-size: 0.85em;
  color: var(--op-create-wp-danger);
`;

const generatedTextStyles = css`
  && {
    grid-area: 1 / 1;
    min-height: 0;
    overflow: hidden;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    font-style: italic;
  }
`;

export const GeneratedField = styled.div`
  display: grid;
`;

export const GeneratedText = styled.span.attrs({ 'aria-hidden': true })`
  ${controlStyles}
  ${generatedTextStyles}
  && {
    visibility: hidden;
  }
`;

export const GeneratedControl = styled.textarea`
  ${controlStyles}
  ${generatedTextStyles}
  && {
    resize: none;
    background: var(--op-create-wp-neutral);
    color: var(--op-create-wp-muted);
    cursor: default;
  }
`;

export const TextAreaControl = styled.textarea`
  ${controlStyles}
  min-height: 72px;
  resize: vertical;
`;

export const CheckboxRow = styled.label`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  font-size: 0.9em;
  cursor: pointer;
`;

export const NoticeLink = styled.a`
  color: var(--op-create-wp-link);
`;

const spin = keyframes`
  to { transform: rotate(360deg); }
`;

export const Spinner = styled.span`
  display: inline-flex;
  animation: ${spin} 0.9s linear infinite;
`;

export const FilterModes = styled.div.attrs({ role: 'group' })`
  display: flex;
  flex-shrink: 0;
`;

export const FilterMode = styled.button.attrs({ type: 'button' })<{ $active:boolean }>`
  && {
    padding: 3px var(--spacer-l);
    border: 1px solid ${({ $active }) => ($active ? controlBorderColor : 'transparent')};
    border-radius: ${radius};
    background: ${({ $active }) => ($active ? 'var(--op-create-wp-neutral)' : 'transparent')};
    color: ${({ $active }) => ($active ? textColor : 'var(--op-create-wp-muted)')};
    font-family: inherit;
    font-size: 12px;
    font-weight: ${({ $active }) => ($active ? 600 : 400)};
    line-height: 1.4;
    cursor: pointer;
  }

  &&:hover {
    color: ${textColor};
  }
`;

const calendarRadius = '5px';
const calendarDayOff = 'var(--bgColor-disabled, var(--op-create-wp-neutral-hover))';
const calendarChecked = 'var(--control-checked-color, var(--bgColor-accent-emphasis, #0969da))';
const calendarCheckedHover = 'var(--control-checked-color--major2, var(--fgColor-accent, #0550ae))';

export const CalendarStyles = createGlobalStyle`
  ${flatpickrStyles}

  .flatpickr-calendar.op-bn-create-wp-calendar {
    position: fixed;
    z-index: 1;
    width: max-content;
    padding: var(--spacer-xs, 4px);
    border-radius: ${radius};
    background: ${surfaceColor};
    box-shadow: var(--shadow-floating-small, var(--op-create-wp-shadow));
    color: ${textColor};
    font-family: inherit;
    font-size: 0.75rem;

    &::before, &::after {
      display: none;
    }

    .flatpickr-months {
      display: flex;
      align-items: flex-start;
      min-height: 45px;
    }

    .flatpickr-month, .flatpickr-weekday {
      color: ${textColor};
      fill: ${textColor};
    }

    .flatpickr-current-month {
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 0.875rem;
      font-weight: 600;

      .numInputWrapper {
        position: relative;
        left: 0;
      }

      .flatpickr-monthDropdown-months {
        background-image: none;
        color: inherit;
      }
    }

    .flatpickr-prev-month, .flatpickr-next-month {
      position: static;
      color: ${textColor};
      fill: ${textColor};

      &:hover svg {
        fill: ${calendarChecked};
      }
    }

    .flatpickr-weekdaycontainer {
      padding: 0;
    }

    .flatpickr-days {
      width: auto;
    }

    .flatpickr-days .dayContainer {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      justify-items: center;
      width: 283px;
      min-width: 283px;
      max-width: 283px;
      padding: 0;
      box-shadow: none;
    }

    .flatpickr-day {
      width: 100%;
      max-width: unset;
      height: 30px;
      margin: 0;
      border-radius: 0;
      background: ${surfaceColor};
      box-shadow: none;
      color: ${textColor};
      line-height: 28px;

      &:hover, &:focus {
        border-color: var(--op-create-wp-muted);
        border-radius: ${calendarRadius};
        background: ${surfaceColor};
      }

      &.prevMonthDay {
        width: 0;
        height: 0;
        visibility: hidden;
      }

      &.nextMonthDay {
        display: none;
      }

      &.flatpickr-non-working-day_enabled {
        background: ${calendarDayOff};
      }

      &.today:not(.selected) {
        border: var(--border-attention-muted, 1px solid rgba(212, 167, 44, 0.4));
        border-radius: ${calendarRadius};
        background: var(--bgColor-attention-muted, #fff8c5);
        color: var(--fgColor-attention, #9a6700);

        &:hover {
          border-color: var(--borderColor-attention-emphasis, #9a6700);
        }
      }

      &.selected {
        border-color: ${calendarChecked};
        border-radius: ${calendarRadius};
        background: ${calendarChecked};
        color: var(--fgColor-onEmphasis, #ffffff);

        &:hover {
          border-color: ${calendarCheckedHover};
          background: ${calendarCheckedHover};
        }
      }
    }

    .flatpickr-time {
      border-top-color: ${borderColor};

      input, .flatpickr-am-pm, .flatpickr-time-separator {
        color: ${textColor};
      }

      input:hover, input:focus, .flatpickr-am-pm:hover, .flatpickr-am-pm:focus {
        background: var(--bgColor-neutral-muted, var(--op-create-wp-action-hover));
      }
    }

    .numInputWrapper {
      &:hover {
        background: var(--bgColor-neutral-muted, var(--op-create-wp-action-hover));
      }

      span {
        border-color: ${borderColor};
      }

      span.arrowUp::after {
        border-bottom-color: ${textColor};
      }

      span.arrowDown::after {
        border-top-color: ${textColor};
      }
    }
  }
`;
