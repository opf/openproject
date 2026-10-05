import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import styled from 'styled-components';
import type { WorkPackage } from '../../openProjectTypes';
import { useWorkPackageSearchDropdown } from '../../hooks/useWorkPackageSearchDropdown';
import { typeColor } from '../../services/colors';
import { formatWorkPackageId } from '../../utils/id';
import { WorkPackageId, WorkPackageType } from '../WorkPackage/atoms';
import { Suggestions, usePickerMotion } from '../CreateWorkPackage/Suggestions';
import { TextControl, TypeaheadWrapper } from '../CreateWorkPackage/atoms';
import type { ListedValue } from '../CreateWorkPackage/formSchema';

const BLUR_DELAY = 150;

// Kept whole: the subject next to it is what gives way.
const Reference = styled.span`
  display: inline-flex;
  align-items: center;
  gap: var(--spacer-m);
  flex-shrink: 0;
  white-space: nowrap;
`;

interface WorkPackagePickerProps {
  id:string;
  label:string;
  selected?:WorkPackage | null;
  autoFocus?:boolean;
  onPick:(workPackage:WorkPackage) => void;
  onEscape:() => void;
}

const referenceOf = (workPackage:WorkPackage) =>
  `${formatWorkPackageId(workPackage.displayId)} ${workPackage.subject}`;

// The search of "Link existing work package" in the look of the pickers
// of the create form.
export const WorkPackagePicker = ({ id, label, selected, autoFocus, onPick, onEscape }:WorkPackagePickerProps) => {
  const { t } = useTranslation();
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  // Typing replaces the picked work package only once another one is picked.
  const [editing, setEditing] = useState(false);
  const listId = `${id}-list`;

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
    setSearchQuery('');
    setIsDropdownOpen(false);
  };

  function pick(workPackage:WorkPackage) {
    restore();
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
  const workPackageOf = (option:{ href:string }) =>
    searchResults.find((workPackage) => String(workPackage.id) === option.href);

  return (
    <TypeaheadWrapper>
      <TextControl
        id={id}
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
        placeholder={t('search.placeholder')}
        value={editing || !selected ? searchQuery : referenceOf(selected)}
        onFocus={(event) => {
          clearTimeout(blurTimerRef.current);
          if (!editing) event.target.select();
        }}
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
          clearTimeout(blurTimerRef.current);
          blurTimerRef.current = setTimeout(restore, BLUR_DELAY);
        }}
      />

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
            if (!workPackage) return null;
            return (
              <Reference>
                <WorkPackageId as="span" $compact>{formatWorkPackageId(workPackage.displayId)}</WorkPackageId>
                {workPackage._links?.type?.title && (
                  <WorkPackageType as="span" $compact $color={typeColor(workPackage)}>
                    {workPackage._links.type.title}
                  </WorkPackageType>
                )}
              </Reference>
            );
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
