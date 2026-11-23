import { useState } from 'react';
import type { SelectPanelItemInput } from '@primer/react';
import { TriangleDownIcon } from '@primer/octicons-react';
import type { PrimerDialogComponents } from '../../services/dialogComponents';
import type { WorkPackageAttribute } from './attributes';

interface AttributePickerProps {
  primer:PrimerDialogComponents;
  id:string;
  label:string;
  placeholder:string;
  attributes:WorkPackageAttribute[];
  selected?:WorkPackageAttribute;
  locale:string;
  onPick:(reference:string) => void;
}

export function PrimerAttributePicker({
  primer: { Button, SelectPanel }, id, label, placeholder, attributes, selected, locale, onPick,
}:AttributePickerProps) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const term = query.trim().toLocaleLowerCase(locale);
  const items = attributes.map(({ reference, label: text }) => ({ id: reference, text }));
  return (
    <SelectPanel
      title={label}
      placeholder={placeholder}
      placeholderText={placeholder}
      inputLabel={label}
      open={open}
      onOpenChange={(next) => {
        setOpen(next);
        if (!next) setQuery('');
      }}
      items={items.filter(({ text }) => text.toLocaleLowerCase(locale).includes(term))}
      selected={items.find((item) => item.id === selected?.reference)}
      onSelectedChange={(item:SelectPanelItemInput | undefined) => onPick(String(item?.id ?? ''))}
      filterValue={query}
      onFilterChange={setQuery}
      overlayProps={{ className: 'op-bn-picker-options' }}
      renderAnchor={({ children, ...props }) => (
        <Button {...props} id={id} block alignContent="start" trailingAction={TriangleDownIcon}
          aria-label={label} aria-describedby={`${id}-value`}>
          <span id={`${id}-value`}>{children}</span>
        </Button>
      )}
    />
  );
}
