import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { XCircleFillIcon } from '@primer/octicons-react';
import { PickerArrowsGlyph } from './PickerArrows';
import { Suggestions } from './Suggestions';
import { usePickerOptions } from './usePickerOptions';
import type { AllowedValue } from './formSchema';
import {
  ACTION_ICON_SIZE,
  FilterMode,
  FilterModes,
  PickerControl,
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
  const [selectedLabel, setSelectedLabel] = useState<string | null>(null);
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);

  const pickedLabel = value ? (selectedLabel ?? valueLabel ?? '') : '';
  const namesPick = isOpen && Boolean(pickedLabel);
  const shownValue = isOpen ? query : pickedLabel;
  const hint = namesPick ? pickedLabel : placeholder;

  const listId = `${id}-list`;
  const { options, loading, toggleExpanded, expand } = usePickerOptions({
    href,
    query,
    isOpen,
    favoredOnly: mode === 'favored',
    nested: true,
  });

  const selectedIndex = options.findIndex((option) => option.href === value);
  const activeIndex = Math.min(
    focusedIndex ?? Math.max(selectedIndex, 0),
    Math.max(0, options.length - 1)
  );

  const open = () => setIsOpen(true);

  const close = (returnFocus = false) => {
    setIsOpen(false);
    setQuery('');
    setFocusedIndex(null);
    if (returnFocus) inputEl?.focus();
  };

  const select = (option:AllowedValue) => {
    setSelectedLabel(option.label);
    expand(option.ancestors ?? []);
    onChange(option.href, option.label);
    close(true);
  };

  const startTerm = (term:string) => {
    setQuery(term);
    setFocusedIndex(0);
    open();
  };

  const deselect = () => {
    setSelectedLabel(null);
    setQuery('');
    setFocusedIndex(null);
    if (value) onChange('');
    inputEl?.focus();
  };

  const handleKeyDown = (event:React.KeyboardEvent) => {
    const focused = options[activeIndex];

    if (!isOpen && event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
      event.preventDefault();
      startTerm(event.key);
      return;
    }

    switch (event.key) {
      case 'Backspace':
      case 'Delete':
        if (value && !query) {
          event.preventDefault();
          deselect();
        }
        break;
      case 'ArrowDown':
        event.preventDefault();
        if (!isOpen) open();
        else setFocusedIndex(Math.max(0, Math.min(activeIndex + 1, options.length - 1)));
        break;
      case 'ArrowUp':
        event.preventDefault();
        if (isOpen) setFocusedIndex(Math.max(activeIndex - 1, 0));
        break;
      case 'ArrowRight':
        if (isOpen && !query && focused?.hasChildren && !focused.expanded) {
          event.preventDefault();
          toggleExpanded(focused.href);
        }
        break;
      case 'ArrowLeft':
        if (isOpen && !query && focused?.expanded) {
          event.preventDefault();
          toggleExpanded(focused.href);
        }
        break;
      case 'Enter':
        event.preventDefault();
        if (!isOpen) open();
        else if (focused) select(focused);
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
    <FilterModes aria-label={t('createWorkPackage.filterBy')}>
      {modeButton('all', t('createWorkPackage.allValues'))}
      {modeButton('favored', t('createWorkPackage.favorites'))}
    </FilterModes>
  );

  const clearable = Boolean(value || query);

  return (
    <TypeaheadWrapper
      $actions={clearable ? 2 : 1}
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
      <PickerControl
        id={id}
        ref={setInputEl}
        $namesPick={namesPick}
        type="text"
        role="combobox"
        aria-expanded={isOpen}
        aria-controls={listId}
        aria-haspopup="tree"
        aria-autocomplete="list"
        aria-activedescendant={isOpen && options[activeIndex] ? optionId(activeIndex) : undefined}
        aria-invalid={invalid ? true : undefined}
        aria-describedby={describedBy}
        autoComplete="off"
        spellCheck={false}
        placeholder={hint}
        value={shownValue}
        onClick={open}
        onChange={(event) => startTerm(event.target.value)}
        onPaste={(event) => {
          if (isOpen) return;
          event.preventDefault();
          startTerm(event.clipboardData.getData('text'));
        }}
        onKeyDown={handleKeyDown}
      />

      <TrailingActions>
        {clearable && (
          <TrailingButton
            aria-label={t(value ? 'createWorkPackage.deselect' : 'createWorkPackage.clear')}
            data-testid={`${id}-clear`}
            onMouseDown={(event) => event.preventDefault()}
            onClick={deselect}
          >
            <XCircleFillIcon size={ACTION_ICON_SIZE} />
          </TrailingButton>
        )}

        <TrailingButton
          aria-label={t(isOpen ? 'createWorkPackage.closeOptions' : 'createWorkPackage.openOptions')}
          aria-expanded={isOpen}
          aria-controls={listId}
          data-testid={`${id}-toggle`}
          onMouseDown={(event) => event.preventDefault()}
          onClick={() => {
            if (isOpen) close();
            else open();
            inputEl?.focus();
          }}
        >
          <PickerArrowsGlyph />
        </TrailingButton>
      </TrailingActions>

      {isOpen && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={inputEl}
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
