import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { XCircleFillIcon } from '@primer/octicons-react';
import { Suggestions } from './Suggestions';
import { usePickerOptions } from './usePickerOptions';
import type { AllowedValue } from './formSchema';
import {
  ACTION_ICON_SIZE,
  TextControl,
  TrailingActions,
  TrailingButton,
  TypeaheadWrapper,
} from './atoms';

const BLUR_DELAY = 150;

interface AllowedValuesTypeaheadProps {
  id:string;
  label:string;
  href:string;
  value:string;
  valueLabel?:string;
  placeholder:string;
  invalid?:boolean;
  describedBy?:string;
  onChange:(href:string, label?:string) => void;
}

export const AllowedValuesTypeahead = ({
  id,
  label,
  href,
  value,
  valueLabel,
  placeholder,
  invalid,
  describedBy,
  onChange,
}:AllowedValuesTypeaheadProps) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState(value ? (valueLabel ?? '') : '');
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState<number | null>(null);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const selectionRef = useRef({ value, label: valueLabel ?? '' });

  const listId = `${id}-list`;
  const { options, loading, toggleExpanded } = usePickerOptions({ href, query, isOpen });
  const selectedIndex = options.findIndex((option) => option.href === value);
  const activeIndex = Math.min(
    focusedIndex ?? Math.max(selectedIndex, 0),
    Math.max(0, options.length - 1)
  );

  useEffect(() => {
    selectionRef.current.value = value;
  }, [value]);

  useEffect(() => () => clearTimeout(blurTimerRef.current), []);

  const select = (option:AllowedValue) => {
    selectionRef.current = { value: option.href, label: option.label };
    setQuery(option.label);
    setIsOpen(false);
    onChange(option.href, option.label);
  };

  const clear = () => {
    selectionRef.current = { value: '', label: '' };
    setQuery('');
    setFocusedIndex(null);
    setIsOpen(true);
    inputEl?.focus();
    if (value) onChange('');
  };

  const handleKeyDown = (event:React.KeyboardEvent<HTMLInputElement>) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (!isOpen) {
          setIsOpen(true);
          break;
        }
        setFocusedIndex(Math.min(activeIndex + 1, options.length - 1));
        break;
      case 'ArrowUp':
        event.preventDefault();
        setFocusedIndex(Math.max(activeIndex - 1, 0));
        break;
      case 'Enter':
        if (isOpen && options[activeIndex]) {
          event.preventDefault();
          select(options[activeIndex]);
        }
        break;
      case 'Escape':
        if (isOpen) {
          event.stopPropagation();
          setIsOpen(false);
        }
        break;
    }
  };

  const optionId = (index:number) => `${id}-option-${index}`;

  return (
    <TypeaheadWrapper>
      <TextControl
        id={id}
        ref={setInputEl}
        type="text"
        role="combobox"
        aria-expanded={isOpen}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={isOpen && options[activeIndex] ? optionId(activeIndex) : undefined}
        aria-invalid={invalid ? true : undefined}
        aria-describedby={describedBy}
        autoComplete="off"
        spellCheck={false}
        placeholder={placeholder}
        value={query}
        onFocus={() => setIsOpen(true)}
        // A click on the already focused field fires no focus event.
        onClick={() => setIsOpen(true)}
        onChange={(event) => {
          setQuery(event.target.value);
          setFocusedIndex(0);
          setIsOpen(true);
          if (value) onChange('');
        }}
        onKeyDown={handleKeyDown}
        onBlur={() => {
          clearTimeout(blurTimerRef.current);
          blurTimerRef.current = setTimeout(() => {
            setIsOpen(false);
            setQuery(selectionRef.current.value ? selectionRef.current.label : '');
          }, BLUR_DELAY);
        }}
      />

      {query && (
        <TrailingActions>
          <TrailingButton
            aria-label={t('createWorkPackage.clear')}
            data-testid={`${id}-clear`}
            onMouseDown={(event) => event.preventDefault()}
            onClick={clear}
          >
            <XCircleFillIcon size={ACTION_ICON_SIZE} />
          </TrailingButton>
        </TrailingActions>
      )}

      {isOpen && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={inputEl}
          options={options}
          focusedIndex={activeIndex}
          selectedHref={value}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={select}
          onDeselect={clear}
          onToggleExpanded={toggleExpanded}
        >
          {loading ? t('createWorkPackage.loading') : t('createWorkPackage.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
