import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { XIcon } from '@primer/octicons-react';
import { Suggestions } from './Suggestions';
import { usePickerOptions } from './usePickerOptions';
import type { AllowedValue } from './formSchema';
import {
  Token,
  TokenField,
  TokenInput,
  TokenLabel,
  TokenRemove,
  TypeaheadWrapper,
} from './atoms';

const BLUR_DELAY = 150;

interface MultiValueTypeaheadProps {
  id:string;
  label:string;
  href?:string;
  allowedValues?:AllowedValue[];
  value:string[];
  placeholder:string;
  invalid?:boolean;
  describedBy?:string;
  onChange:(hrefs:string[]) => void;
}

export const MultiValueTypeahead = ({
  id,
  label,
  href,
  allowedValues,
  value,
  placeholder,
  invalid,
  describedBy,
  onChange,
}:MultiValueTypeaheadProps) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState(0);
  const [inputEl, setInputEl] = useState<HTMLInputElement | null>(null);
  const [fieldEl, setFieldEl] = useState<HTMLDivElement | null>(null);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [picked, setPicked] = useState<AllowedValue[]>([]);

  useEffect(() => () => clearTimeout(blurTimerRef.current), []);

  const listId = `${id}-list`;
  const { options, loading, toggleExpanded } = usePickerOptions({
    href: href ?? '',
    query,
    isOpen,
    values: allowedValues,
  });

  const offered = options.filter((option) => !value.includes(option.href));
  const tokens = value.flatMap((href) => {
    const named = allowedValues?.find((option) => option.href === href)
      ?? picked.find((option) => option.href === href);
    return named ? [named] : [];
  });
  const activeIndex = Math.min(focusedIndex, Math.max(0, offered.length - 1));

  const open = () => {
    clearTimeout(blurTimerRef.current);
    setIsOpen(true);
    setFocusedIndex(0);
  };

  const add = (option:AllowedValue) => {
    setPicked((held) => [...held.filter((one) => one.href !== option.href), option]);
    setQuery('');
    setIsOpen(false);
    onChange([...value, option.href]);
  };

  const remove = (removed:string) => {
    onChange(value.filter((held) => held !== removed));
    inputEl?.focus();
  };

  const handleKeyDown = (event:React.KeyboardEvent<HTMLInputElement>) => {
    switch (event.key) {
      case 'Backspace':
        if (query || value.length === 0) break;
        event.preventDefault();
        remove(value[value.length - 1]);
        break;
      case 'ArrowDown':
        event.preventDefault();
        if (!isOpen) open();
        else setFocusedIndex(Math.max(0, Math.min(activeIndex + 1, offered.length - 1)));
        break;
      case 'ArrowUp':
        event.preventDefault();
        if (isOpen) setFocusedIndex(Math.max(activeIndex - 1, 0));
        break;
      case 'Enter':
        if (isOpen && offered[activeIndex]) {
          event.preventDefault();
          add(offered[activeIndex]);
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
      <TokenField
        ref={setFieldEl}
        $invalid={invalid}
        onMouseDown={(event) => {
          if (event.target === event.currentTarget) inputEl?.focus();
        }}
      >
        {tokens.map((token) => (
          <Token key={token.href}>
            <TokenLabel>{token.label}</TokenLabel>
            <TokenRemove
              type="button"
              aria-label={t('createWorkPackage.removeValue', { value: token.label })}
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => remove(token.href)}
            >
              <XIcon size={12} />
            </TokenRemove>
          </Token>
        ))}

        <TokenInput
          id={id}
          ref={setInputEl}
          type="text"
          role="combobox"
          aria-expanded={isOpen}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={isOpen && offered[activeIndex] ? optionId(activeIndex) : undefined}
          aria-invalid={invalid ? true : undefined}
          aria-describedby={describedBy}
          autoComplete="off"
          spellCheck={false}
          placeholder={tokens.length > 0 ? undefined : placeholder}
          value={query}
          onFocus={open}
          onClick={open}
          onChange={(event) => {
            setQuery(event.target.value);
            open();
          }}
          onKeyDown={handleKeyDown}
          onBlur={() => {
            clearTimeout(blurTimerRef.current);
            blurTimerRef.current = setTimeout(() => {
              setIsOpen(false);
              setQuery('');
            }, BLUR_DELAY);
          }}
        />
      </TokenField>

      {isOpen && (
        <Suggestions
          id={listId}
          label={label}
          anchorEl={fieldEl}
          options={offered}
          focusedIndex={activeIndex}
          optionId={optionId}
          onFocusIndex={setFocusedIndex}
          onPick={add}
          onToggleExpanded={toggleExpanded}
        >
          {loading ? t('createWorkPackage.loading') : t('createWorkPackage.noResults')}
        </Suggestions>
      )}
    </TypeaheadWrapper>
  );
};
