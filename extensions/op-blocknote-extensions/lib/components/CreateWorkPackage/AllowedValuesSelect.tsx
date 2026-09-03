import { useMemo, useRef, useState } from 'react';
import type { KeyboardEvent, ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { PickerArrowsGlyph } from './PickerArrows';
import { Suggestions, usePickerMotion } from './Suggestions';
import type { AllowedValue, ListedValue } from './formSchema';
import {
  OptionColorDot,
  PickerControl,
  TrailingActions,
  TrailingButton,
  TypeColorDot,
  TypeaheadWrapper,
} from './atoms';

const isPrintable = (event:KeyboardEvent):boolean =>
  event.key.length === 1 && !event.altKey && !event.ctrlKey && !event.metaKey;

function indexStartingWith(options:ListedValue[], term:string, from:number):number {
  const wanted = term.toLowerCase();

  for (let step = 0; step < options.length; step += 1) {
    const index = (from + step + options.length) % options.length;
    if (options[index].label.toLowerCase().startsWith(wanted)) return index;
  }

  return -1;
}

export interface AllowedValuesSelectProps {
  id:string;
  label:string;
  options:AllowedValue[];
  value:string;
  placeholder:string;
  colorOf?:(href:string) => string;
  invalid?:boolean;
  describedBy?:string;
  onChange:(href:string) => void;
}

export const AllowedValuesSelect = ({
  id,
  label,
  options,
  value,
  placeholder,
  colorOf,
  invalid,
  describedBy,
  onChange,
}:AllowedValuesSelectProps) => {
  const { t } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState<number | null>(null);
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const listId = `${id}-list`;
  const { mounted, open: listShown, onClosed } = usePickerMotion(isOpen);

  const listed = useMemo<ListedValue[]>(() => options.map((option, index) => ({
    ...option,
    depth: 0,
    hasChildren: false,
    expanded: false,
    position: index + 1,
    levelSize: options.length,
  })), [options]);
  const selected = listed.find((option) => option.href === value);
  const selectedIndex = selected ? listed.indexOf(selected) : -1;
  const selectedColor = value ? colorOf?.(value) : undefined;

  const activeIndex = Math.min(
    focusedIndex ?? Math.max(selectedIndex, 0),
    Math.max(0, listed.length - 1)
  );

  const live = useRef({ isOpen: false, index: 0 });
  const typedTerm = useRef('');

  const setOpen = (next:boolean) => {
    live.current.isOpen = next;
    if (!next) typedTerm.current = '';
    setIsOpen(next);
  };

  const focusOn = (index:number) => {
    live.current.index = index;
    setFocusedIndex(index);
  };

  const open = () => {
    focusOn(Math.max(selectedIndex, 0));
    setOpen(true);
  };

  const pick = (option:AllowedValue | undefined) => {
    if (!option) return;
    setOpen(false);
    onChange(option.href);
  };

  const deselect = () => {
    setOpen(false);
    if (value) onChange('');
  };

  const handleKeyDown = (event:KeyboardEvent) => {
    const { isOpen: shown, index } = live.current;

    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowUp':
        typedTerm.current = '';
        event.preventDefault();
        if (!shown) open();
        else if (listed.length > 0) {
          focusOn(Math.max(0, Math.min(index + (event.key === 'ArrowDown' ? 1 : -1), listed.length - 1)));
        }
        return;
      case 'Home':
      case 'End':
        if (!shown || listed.length === 0) return;
        typedTerm.current = '';
        event.preventDefault();
        focusOn(event.key === 'Home' ? 0 : listed.length - 1);
        return;
      case ' ':
        if (typedTerm.current) break;
        event.preventDefault();
        if (shown) pick(listed[index]);
        else open();
        return;
      case 'Enter':
        if (!shown) return;
        event.preventDefault();
        pick(listed[index]);
        return;
      case 'Escape':
        if (!shown) return;
        event.stopPropagation();
        setOpen(false);
        return;
      case 'Tab':
        setOpen(false);
        return;
    }

    if (!isPrintable(event)) return;

    const from = shown ? index : Math.max(selectedIndex, 0);
    const grown = typedTerm.current + event.key;
    let term = grown;
    let landing = indexStartingWith(listed, grown, from);

    if (landing < 0) {
      term = event.key;
      landing = indexStartingWith(listed, term, from + 1);
    }

    typedTerm.current = landing < 0 ? '' : term;
    if (landing < 0) return;

    event.preventDefault();
    if (!shown) setOpen(true);
    focusOn(landing);
  };

  const dotFor = (href:string):ReactNode => {
    const color = colorOf?.(href);
    return color ? <OptionColorDot $color={color} /> : null;
  };

  return (
    <TypeaheadWrapper
      $withColorDot={Boolean(selectedColor)}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false);
      }}
    >
      <PickerControl
        id={id}
        ref={setInputEl}
        $namesPick
        type="text"
        role="combobox"
        readOnly
        aria-expanded={isOpen}
        aria-controls={listId}
        aria-haspopup="listbox"
        aria-activedescendant={isOpen && listed[activeIndex] ? `${listId}-option-${activeIndex}` : undefined}
        aria-invalid={invalid ? true : undefined}
        aria-describedby={describedBy}
        autoComplete="off"
        placeholder={placeholder}
        value={selected?.label ?? ''}
        onClick={() => { if (isOpen) setOpen(false); else open(); }}
        onKeyDown={handleKeyDown}
      />

      {selectedColor && <TypeColorDot $color={selectedColor} />}

      <TrailingActions>
        <TrailingButton
          aria-label={t(isOpen ? 'createWorkPackage.closeOptions' : 'createWorkPackage.openOptions')}
          aria-expanded={isOpen}
          aria-controls={listId}
          data-testid={`${id}-toggle`}
          onMouseDown={(event) => event.preventDefault()}
          onClick={() => {
            if (isOpen) setOpen(false);
            else open();
            inputEl?.focus();
          }}
        >
          <PickerArrowsGlyph />
        </TrailingButton>
      </TrailingActions>

      {mounted && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={inputEl}
          options={listed}
          focusedIndex={activeIndex}
          selectedHref={value}
          optionId={(index) => `${listId}-option-${index}`}
          onFocusIndex={focusOn}
          onPick={pick}
          onDeselect={deselect}
          onToggleExpanded={() => undefined}
          leadingOf={(option) => dotFor(option.href)}
          open={listShown}
          onClosed={onClosed}
        >
          {t('createWorkPackage.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
