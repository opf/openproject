import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SearchIcon as SearchGlyph, XCircleFillIcon } from '@primer/octicons-react';
import { PickerArrowsGlyph } from './PickerArrows';
import { Suggestions } from './Suggestions';
import { usePickerOptions } from './usePickerOptions';
import type { AllowedValue } from './formSchema';
import {
  ACTION_ICON_SIZE,
  FilterMode,
  FilterModes,
  SearchBox,
  SearchControl,
  SearchIcon,
  TextControl,
  TrailingActions,
  TrailingButton,
  TypeaheadWrapper,
} from './atoms';

type FilterModeName = 'all' | 'favored';

export interface ProjectPickerProps {
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

export const ProjectPicker = ({
  id,
  label,
  href,
  value,
  valueLabel,
  placeholder,
  invalid,
  describedBy,
  onChange,
}:ProjectPickerProps) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState<number | null>(null);
  const [mode, setMode] = useState<FilterModeName>('all');
  const [pickedLabel, setPickedLabel] = useState<string | null>(null);
  const [triggerEl, setTriggerEl] = useState<HTMLInputElement | null>(null);
  const searchRef = useRef<HTMLInputElement>(null);

  const listId = `${id}-list`;
  const { options, loading, toggleExpanded, expand } = usePickerOptions({
    href,
    query,
    isOpen,
    favoredOnly: mode === 'favored',
    nested: true,
    cached: true,
  });

  const selectedIndex = options.findIndex((option) => option.href === value);
  const activeIndex = Math.min(
    focusedIndex ?? Math.max(selectedIndex, 0),
    Math.max(0, options.length - 1)
  );

  const shownLabel = value ? (pickedLabel ?? valueLabel ?? '') : '';

  useEffect(() => {
    if (isOpen) searchRef.current?.focus();
  }, [isOpen]);

  const open = () => setIsOpen(true);

  const close = (returnFocus = false) => {
    setIsOpen(false);
    setQuery('');
    setFocusedIndex(null);
    if (returnFocus) triggerEl?.focus();
  };

  const select = (option:AllowedValue) => {
    setPickedLabel(option.label);
    expand(option.ancestors ?? []);
    onChange(option.href, option.label);
    close(true);
  };

  const deselect = () => {
    setPickedLabel(null);
    onChange('');
    searchRef.current?.focus();
  };

  const handleKeyDown = (event:React.KeyboardEvent) => {
    const focused = options[activeIndex];

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        setFocusedIndex(Math.max(0, Math.min(activeIndex + 1, options.length - 1)));
        break;
      case 'ArrowUp':
        event.preventDefault();
        setFocusedIndex(Math.max(activeIndex - 1, 0));
        break;
      case 'ArrowRight':
        if (!query && focused?.hasChildren && !focused.expanded) {
          event.preventDefault();
          toggleExpanded(focused.href);
        }
        break;
      case 'ArrowLeft':
        if (!query && focused?.expanded) {
          event.preventDefault();
          toggleExpanded(focused.href);
        }
        break;
      case 'Enter':
        event.preventDefault();
        if (focused) select(focused);
        break;
      case 'Escape':
        event.stopPropagation();
        close(true);
        break;
    }
  };

  const optionId = (index:number) => `${id}-option-${index}`;

  const modeButton = (name:FilterModeName, text:string) => (
    <FilterMode
      $active={mode === name}
      aria-pressed={mode === name}
      data-testid={`${listId}-mode-${name}`}
      onMouseDown={(event) => event.preventDefault()}
      onClick={() => {
        setMode(name);
        setFocusedIndex(null);
      }}
    >
      {text}
    </FilterMode>
  );

  const header = (
    <>
      <SearchBox>
        <SearchIcon>
          <SearchGlyph size={14} />
        </SearchIcon>
        <SearchControl
          ref={searchRef}
          type="text"
          role="combobox"
          aria-haspopup="tree"
          aria-expanded
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={options[activeIndex] ? optionId(activeIndex) : undefined}
          aria-label={t('createWorkPackage.searchPlaceholder')}
          autoComplete="off"
          spellCheck={false}
          data-testid={`${id}-search`}
          value={query}
          onChange={(event) => {
            setQuery(event.target.value);
            setFocusedIndex(0);
          }}
          onKeyDown={handleKeyDown}
        />
        <TrailingActions>
          <TrailingButton
            aria-label={t('createWorkPackage.clear')}
            data-testid={`${id}-clear`}
            onMouseDown={(event) => event.preventDefault()}
            onClick={() => {
              setQuery('');
              setFocusedIndex(null);
              searchRef.current?.focus();
            }}
          >
            <XCircleFillIcon size={ACTION_ICON_SIZE} />
          </TrailingButton>
        </TrailingActions>
      </SearchBox>

      <FilterModes aria-label={t('createWorkPackage.filterBy')}>
        {modeButton('all', t('createWorkPackage.allValues'))}
        {modeButton('favored', t('createWorkPackage.favorites'))}
      </FilterModes>
    </>
  );

  return (
    <TypeaheadWrapper
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) close();
      }}
      onKeyDown={(event) => {
        if (event.key === 'Escape' && isOpen) {
          event.stopPropagation();
          close(true);
        }
      }}
    >
      <TextControl
        id={id}
        ref={setTriggerEl}
        type="text"
        role="combobox"
        readOnly
        aria-expanded={isOpen}
        aria-controls={listId}
        aria-haspopup="tree"
        aria-invalid={invalid ? true : undefined}
        aria-describedby={describedBy}
        placeholder={placeholder}
        value={shownLabel}
        onClick={() => (isOpen ? close() : open())}
        onKeyDown={(event) => {
          if (event.key === 'ArrowDown' || event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            open();
          }
        }}
      />

      <TrailingActions>
        <TrailingButton
          aria-label={t(isOpen ? 'createWorkPackage.closeOptions' : 'createWorkPackage.openOptions')}
          aria-expanded={isOpen}
          aria-controls={listId}
          data-testid={`${id}-toggle`}
          onMouseDown={(event) => event.preventDefault()}
          onClick={() => {
            if (isOpen) close(true);
            else open();
            triggerEl?.focus();
          }}
        >
          <PickerArrowsGlyph />
        </TrailingButton>
      </TrailingActions>

      {isOpen && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={triggerEl}
          options={options}
          focusedIndex={activeIndex}
          selectedHref={value}
          hierarchical
          header={header}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={select}
          onDeselect={deselect}
          onToggleExpanded={toggleExpanded}
        >
          {loading ? t('createWorkPackage.loading') : t('createWorkPackage.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
