import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { fetchAllowedValues } from '../../services/openProjectApi';
import { useAnchoredPopover } from '../WorkPackage/anchoredPopover';
import { PickerArrows } from './PickerArrows';
import { toAllowedValues } from './formSchema';
import type { AllowedValue } from './formSchema';
import {
  SuggestionEmpty,
  SuggestionItem,
  SuggestionList,
  TextControl,
  TypeaheadWrapper,
} from './atoms';

const SEARCH_DEBOUNCE = 300;
const BLUR_DELAY = 150;
const MAX_RESULTS = 10;
const MAX_LIST_HEIGHT = 220;
const LIST_OFFSET = 2;

interface SuggestionsProps {
  id:string;
  label:string;
  anchorEl:HTMLElement | null;
  options:AllowedValue[];
  focusedIndex:number;
  optionId:(index:number) => string;
  onFocusIndex:(index:number) => void;
  onPick:(option:AllowedValue) => void;
  children:React.ReactNode;
}

const Suggestions = ({
  id,
  label,
  anchorEl,
  options,
  focusedIndex,
  optionId,
  onFocusIndex,
  onPick,
  children,
}:SuggestionsProps) => {
  const listRef = useRef<HTMLDivElement>(null);

  useAnchoredPopover({
    anchorEl,
    popoverRef: listRef,
    placement: 'below',
    offset: LIST_OFFSET,
    matchAnchorWidth: true,
    maxHeight: MAX_LIST_HEIGHT,
    resizeKey: options.length,
  });

  return (
    <SuggestionList ref={listRef} id={id} aria-label={label}>
      {options.map((option, index) => (
        <SuggestionItem
          key={option.href}
          id={optionId(index)}
          aria-selected={index === focusedIndex}
          $focused={index === focusedIndex}
          onMouseEnter={() => onFocusIndex(index)}
          onMouseDown={(event) => {
            event.preventDefault();
            onPick(option);
          }}
        >
          {option.label}
        </SuggestionItem>
      ))}
      {options.length === 0 && <SuggestionEmpty>{children}</SuggestionEmpty>}
    </SuggestionList>
  );
};

interface AllowedValuesTypeaheadProps {
  id:string;
  label:string;
  href:string;
  value:string;
  placeholder:string;
  withArrows?:boolean;
  invalid?:boolean;
  describedBy?:string;
  onChange:(href:string) => void;
}

export const AllowedValuesTypeahead = ({
  id,
  label,
  href,
  value,
  placeholder,
  withArrows,
  invalid,
  describedBy,
  onChange,
}:AllowedValuesTypeaheadProps) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  const [options, setOptions] = useState<AllowedValue[]>([]);
  const [loadedQuery, setLoadedQuery] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState(0);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const selectionRef = useRef({ value, label: '' });

  const loading = loadedQuery !== query;

  useEffect(() => {
    selectionRef.current.value = value;
  }, [value]);

  useEffect(() => () => clearTimeout(blurTimerRef.current), []);

  useEffect(() => {
    if (!isOpen) return;

    let active = true;

    const timer = setTimeout(() => {
      fetchAllowedValues(href, query)
        .then(({ resources, filtered }) => {
          if (!active) return;
          // Narrowed here only where the API could not: it also matches on what
          // the option does not read as, an e-mail among it.
          const term = filtered ? '' : query.trim().toLowerCase();
          setOptions(
            toAllowedValues(resources)
              .filter((option) => !term || option.label.toLowerCase().includes(term))
              .slice(0, MAX_RESULTS)
          );
          setFocusedIndex(0);
        })
        .catch((error:unknown) => {
          if (!active) return;
          console.error('[create work package] Failed to load allowed values:', error);
          setOptions([]);
        })
        .finally(() => {
          if (active) setLoadedQuery(query);
        });
    }, SEARCH_DEBOUNCE);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [href, query, isOpen]);

  const select = (option:AllowedValue) => {
    selectionRef.current = { value: option.href, label: option.label };
    setQuery(option.label);
    setIsOpen(false);
    onChange(option.href);
  };

  const handleKeyDown = (event:React.KeyboardEvent<HTMLInputElement>) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (!isOpen) {
          setIsOpen(true);
          break;
        }
        setFocusedIndex((index) => Math.max(0, Math.min(index + 1, options.length - 1)));
        break;
      case 'ArrowUp':
        event.preventDefault();
        setFocusedIndex((index) => Math.max(index - 1, 0));
        break;
      case 'Enter':
        if (isOpen && options[focusedIndex]) {
          event.preventDefault();
          select(options[focusedIndex]);
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
    <TypeaheadWrapper $withArrows={withArrows}>
      <TextControl
        id={id}
        ref={setInputEl}
        type="text"
        role="combobox"
        aria-expanded={isOpen}
        aria-controls={`${id}-list`}
        aria-autocomplete="list"
        aria-activedescendant={isOpen && options[focusedIndex] ? optionId(focusedIndex) : undefined}
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

      {withArrows && <PickerArrows />}

      {isOpen && (
        <Suggestions
          id={`${id}-list`}
          label={label}
          anchorEl={inputEl}
          options={options}
          focusedIndex={focusedIndex}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={select}
        >
          {loading ? t('createWorkPackage.loading') : t('createWorkPackage.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
