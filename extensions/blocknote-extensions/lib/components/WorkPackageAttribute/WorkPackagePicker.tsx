import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { XCircleFillIcon } from '@primer/octicons-react';
import type { WorkPackage } from '../../openProjectTypes';
import { useWorkPackageSearchDropdown } from '../../hooks/useWorkPackageSearchDropdown';
import { typeColor } from '../../services/colors';
import { formatWorkPackageId } from '../../utils/id';
import { WorkPackageId, WorkPackageType } from '../WorkPackage/atoms';
import { Suggestions, usePickerMotion } from '../Shared/Suggestions';
import {
  ACTION_ICON_SIZE,
  PickerControl,
  TrailingActions,
  TrailingButton,
  TypeaheadWrapper,
} from '../Shared/atoms';
import type { ListedValue } from '../Shared/options';
import { PickerToggle, toggleList } from '../Shared/PickerToggle';
import { SelectedSubject, SelectedText, SelectedWorkPackage, WorkPackageReference } from './atoms';

const BLUR_DELAY = 150;

const Reference = ({ workPackage }:{ workPackage:WorkPackage }) => (
  <WorkPackageReference>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(workPackage.displayId)}</WorkPackageId>
    {workPackage._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(workPackage)}>
        {workPackage._links.type.title}
      </WorkPackageType>
    )}
  </WorkPackageReference>
);

interface WorkPackagePickerProps {
  id:string;
  label:string;
  selected?:WorkPackage | null;
  autoFocus?:boolean;
  onPick:(workPackage:WorkPackage) => void;
  onDeselect:() => void;
  onEscape:() => void;
}

export const WorkPackagePicker = ({ id, label, selected, autoFocus, onPick, onDeselect, onEscape }:WorkPackagePickerProps) => {
  const { t } = useTranslation();
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  // Typing replaces the picked work package only once another one is picked.
  const [editing, setEditing] = useState(false);
  const [marked, setMarked] = useState(false);
  const listId = `${id}-list`;
  const selectedId = `${id}-selected`;

  const {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
    focusedIndex,
    setFocusedIndex,
    isDropdownOpen,
    setIsDropdownOpen,
    handleKeyDown,
  } = useWorkPackageSearchDropdown({ onSelect: (workPackage) => pick(workPackage), onEscape });
  const { mounted, open, onClosed } = usePickerMotion(isDropdownOpen);

  useEffect(() => {
    if (autoFocus) inputEl?.focus();
  }, [autoFocus, inputEl]);

  useEffect(() => () => clearTimeout(blurTimerRef.current), []);

  const restore = () => {
    setEditing(false);
    setIsDropdownOpen(false);
  };

  const openLastSearch = () => {
    if (!searchQuery) return;

    const selectedIndex = searchResults.findIndex((workPackage) => workPackage.id === selected?.id);
    setEditing(true);
    setFocusedIndex(Math.max(selectedIndex, 0));
    setIsDropdownOpen(true);
  };

  const toggle = (next:boolean) => toggleList(next, {
    open: openLastSearch,
    close: () => (selected ? restore() : setIsDropdownOpen(false)),
    field: inputEl,
  });

  function pick(workPackage:WorkPackage) {
    restore();
    setMarked(false);
    onPick(workPackage);
  }

  const clear = () => {
    restore();
    if (selected) onDeselect();
    inputEl?.focus();
  };

  const options:ListedValue[] = searchResults.map((workPackage, index) => ({
    href: String(workPackage.id),
    label: workPackage.subject,
    depth: 0,
    hasChildren: false,
    expanded: false,
    position: index + 1,
    levelSize: searchResults.length,
  }));
  const optionId = (index:number) => `${id}-option-${index}`;
  const showsSelected = !!selected && !editing;
  const clearable = !!selected || (editing && !!searchQuery);
  const actions = clearable ? 2 : 1;
  const workPackageOf = (option:{ href:string }) =>
    searchResults.find((workPackage) => String(workPackage.id) === option.href);

  return (
    <TypeaheadWrapper $actions={actions}>
      <PickerControl
        id={id}
        $namesPick
        ref={setInputEl}
        type="text"
        role="combobox"
        aria-expanded={isDropdownOpen}
        aria-haspopup="listbox"
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={isDropdownOpen && options[focusedIndex] ? optionId(focusedIndex) : undefined}
        autoComplete="off"
        spellCheck={false}
        aria-describedby={showsSelected ? selectedId : undefined}
        placeholder={showsSelected ? undefined : t('search.placeholder')}
        value={editing ? searchQuery : ''}
        onFocus={() => {
          clearTimeout(blurTimerRef.current);
          setMarked(true);
        }}
        onMouseDown={() => setMarked(true)}
        onChange={(event) => {
          setEditing(true);
          setSearchQuery(event.target.value);
          setIsDropdownOpen(event.target.value.length > 0);
        }}
        onKeyDown={(event) => {
          switch (event.key) {
            case 'Escape':
              // One step at a time: the search first, then whatever holds the picker.
              event.stopPropagation();
              if (editing || isDropdownOpen) restore();
              else onEscape();
              return;
            case 'ArrowDown':
              if (isDropdownOpen) break;
              event.preventDefault();
              openLastSearch();
              return;
            case 'Enter':
              // The results of the last search stay around while the list is closed.
              if (!isDropdownOpen) return;
              break;
            case 'Backspace':
            case 'Delete':
              if (!showsSelected) break;
              event.preventDefault();
              clear();
              return;
          }
          handleKeyDown(event);
        }}
        onBlur={() => {
          setMarked(false);
          clearTimeout(blurTimerRef.current);
          blurTimerRef.current = setTimeout(restore, BLUR_DELAY);
        }}
      />

      {showsSelected && (
        <SelectedWorkPackage id={selectedId} data-testid={selectedId} $actions={actions}>
          <SelectedText $marked={marked}>
            <Reference workPackage={selected} />
            <SelectedSubject>{selected.subject}</SelectedSubject>
          </SelectedText>
        </SelectedWorkPackage>
      )}

      <TrailingActions>
        {clearable && (
          <TrailingButton
            aria-label={t(selected ? 'createWorkPackage.deselect' : 'createWorkPackage.clear')}
            data-testid={`${id}-clear`}
            onMouseDown={(event) => event.preventDefault()}
            onClick={clear}
          >
            <XCircleFillIcon size={ACTION_ICON_SIZE} />
          </TrailingButton>
        )}

        <PickerToggle
          isOpen={isDropdownOpen}
          controls={listId}
          testId={`${id}-toggle`}
          onToggle={toggle}
        />
      </TrailingActions>

      {mounted && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={inputEl}
          options={options}
          focusedIndex={focusedIndex}
          selectedHref={selected ? String(selected.id) : undefined}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={(option) => {
            const workPackage = workPackageOf(option);
            if (workPackage) pick(workPackage);
          }}
          onDeselect={clear}
          onToggleExpanded={() => undefined}
          leadingOf={(option) => {
            const workPackage = workPackageOf(option);
            return workPackage ? <Reference workPackage={workPackage} /> : null;
          }}
          open={open}
          onClosed={onClosed}
        >
          {loading ? t('createWorkPackage.loading') : t(error ? 'search.error' : 'search.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
