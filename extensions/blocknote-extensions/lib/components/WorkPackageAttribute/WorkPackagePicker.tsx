import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { useWorkPackageSearchDropdown } from '../../hooks/useWorkPackageSearchDropdown';
import { typeColor } from '../../services/colors';
import { formatWorkPackageId } from '../../utils/id';
import { WorkPackageId, WorkPackageType } from '../WorkPackage/atoms';
import { Suggestions, usePickerMotion } from '../CreateWorkPackage/Suggestions';
import { PickerControl, TrailingActions, TypeaheadWrapper } from '../CreateWorkPackage/atoms';
import type { ListedValue } from '../CreateWorkPackage/formSchema';
import { PickerToggle } from '../CreateWorkPackage/PickerToggle';
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
  onEscape:() => void;
}


// The search of "Link existing work package" in the look of the pickers
// of the create form.
export const WorkPackagePicker = ({ id, label, selected, autoFocus, onPick, onEscape }:WorkPackagePickerProps) => {
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

  const onListClosed = useCallback(() => {
    onClosed();
    if (!editing) setSearchQuery('');
  }, [onClosed, editing, setSearchQuery]);

  // The query stays until the list has rolled up, so its rows do not empty out on the way.
  const restore = () => {
    setEditing(false);
    setIsDropdownOpen(false);
    if (!mounted) setSearchQuery('');
  };

  function pick(workPackage:WorkPackage) {
    restore();
    setMarked(false);
    onPick(workPackage);
  }

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
  const workPackageOf = (option:{ href:string }) =>
    searchResults.find((workPackage) => String(workPackage.id) === option.href);

  return (
    <TypeaheadWrapper>
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
          if (event.key !== 'Escape') {
            handleKeyDown(event);
            return;
          }
          // One step at a time: the search first, then whatever holds the picker.
          event.stopPropagation();
          if (editing || isDropdownOpen) restore();
          else onEscape();
        }}
        onBlur={() => {
          setMarked(false);
          clearTimeout(blurTimerRef.current);
          blurTimerRef.current = setTimeout(restore, BLUR_DELAY);
        }}
      />

      {showsSelected && (
        <SelectedWorkPackage id={selectedId} data-testid={selectedId}>
          <SelectedText $marked={marked}>
            <Reference workPackage={selected} />
            <SelectedSubject>{selected.subject}</SelectedSubject>
          </SelectedText>
        </SelectedWorkPackage>
      )}

      <TrailingActions>
        <PickerToggle
          isOpen={isDropdownOpen}
          controls={listId}
          testId={`${id}-toggle`}
          onToggle={() => inputEl?.focus()}
        />
      </TrailingActions>

      {mounted && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={inputEl}
          options={options}
          focusedIndex={focusedIndex}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={(option) => {
            const workPackage = workPackageOf(option);
            if (workPackage) pick(workPackage);
          }}
          onToggleExpanded={() => undefined}
          leadingOf={(option) => {
            const workPackage = workPackageOf(option);
            return workPackage ? <Reference workPackage={workPackage} /> : null;
          }}
          open={open}
          onClosed={onListClosed}
        >
          {loading ? t('createWorkPackage.loading') : t(error ? 'search.error' : 'search.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
