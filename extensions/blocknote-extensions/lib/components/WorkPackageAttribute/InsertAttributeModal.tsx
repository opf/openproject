import { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import styled from 'styled-components';
import { AlertIcon, XIcon } from '@primer/octicons-react';
import type { WorkPackage } from '../../openProjectTypes';
import { useColors } from '../../services/colors';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useWorkPackageSchema } from '../../hooks/useWorkPackageSchema';
import { formatWorkPackageId } from '../../utils/id';
import { FullPagePortal, keepFocusInside, usePageScrollLock } from '../WorkPackage/modal';
import { AllowedValuesSelect } from '../CreateWorkPackage/AllowedValuesSelect';
import {
  Body,
  BodyContent,
  Button,
  FieldHint,
  FieldLabel,
  FieldRow,
  Footer,
  Header,
  HeaderTitle,
  IconButton,
  Overlay,
  Panel,
  PickerControl,
  RequiredMark,
} from '../CreateWorkPackage/atoms';
import { findAttribute, formatAttributeValue, listAttributes } from './attributes';
import type { AttributeDisplay } from './externalHtml';
import type { AttributeChoice } from './pending';
import { AttributeChipSurface, WorkPackageAttributeView } from './WorkPackageAttributeChip';
import { useAttributeFormatOptions } from './useWorkPackageAttribute';
import { WorkPackagePicker } from './WorkPackagePicker';

const ATTRIBUTE_CONTROL_ID = 'op-bn-wp-attribute-select';

const WORK_PACKAGE_CONTROL_ID = 'op-bn-wp-attribute-work-package';

// What the chip in the preview is drawn with.
const EDITOR_VARIABLES = [
  '--bn-colors-editor-text',
  '--bn-colors-highlights-blue-text',
  '--bn-border-radius',
];

const DISPLAYS:AttributeDisplay[] = ['label', 'value', 'both'];

const AttributeLabel = styled(FieldLabel)<{ $disabled:boolean }>`
  color: ${({ $disabled }) => ($disabled ? 'var(--op-create-wp-muted)' : 'var(--op-create-wp-text)')};
`;

// Tripled to outweigh the doubled rules the control shares with the form.
const DisabledControl = styled(PickerControl)`
  &&&:disabled {
    background: var(--op-create-wp-neutral);
    color: var(--op-create-wp-muted);
    cursor: not-allowed;
    opacity: 1;
  }
`;

const DisplayOptions = styled.div.attrs({ role: 'radiogroup' })`
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 2px;
  padding: 3px;
  border-radius: var(--bn-border-radius-medium, 8px);
  background: var(--op-create-wp-neutral);
`;

const DisplayOption = styled.button.attrs({ type: 'button', role: 'radio' })<{ $active:boolean }>`
  && {
    padding: 6px var(--spacer-m);
    border: 1px solid ${({ $active }) => ($active ? 'var(--op-create-wp-control-border)' : 'transparent')};
    border-radius: var(--bn-border-radius-small, 6px);
    background: ${({ $active }) => ($active ? 'var(--op-create-wp-surface)' : 'transparent')};
    color: ${({ $active }) => ($active ? 'var(--op-create-wp-text)' : 'var(--op-create-wp-muted)')};
    font-family: inherit;
    font-size: 13px;
    font-weight: ${({ $active }) => ($active ? 600 : 500)};
    cursor: pointer;
  }
`;

const PreviewLabel = styled.div`
  margin-bottom: var(--spacer-s);
  font-size: 12px;
  color: var(--op-create-wp-muted);
`;

const PreviewBox = styled.div`
  min-height: 44px;
  line-height: 1.6;
  overflow-wrap: anywhere;
  padding: var(--spacer-m) var(--spacer-l);
  border: 1px solid var(--op-create-wp-border);
  border-radius: var(--bn-border-radius-small, 6px);
  background: var(--op-create-wp-neutral);
  font-size: 14px;
`;

const PreviewPlaceholder = styled.span`
  color: var(--op-create-wp-placeholder);
  font-size: 13px;
`;

export interface InsertAttributeModalProps {
  anchorEl?:HTMLElement | null;
  prefill?:AttributeChoice;
  onInsert:(choice:AttributeChoice) => void;
  onCancel:() => void;
}

export const InsertAttributeModal = ({ anchorEl, prefill, onInsert, onCancel }:InsertAttributeModalProps) => {
  const { t } = useTranslation();
  const panelRef = useRef<HTMLDivElement>(null);
  usePageScrollLock();
  useColors();
  const formatOptions = useAttributeFormatOptions();

  const [picked, setPicked] = useState<WorkPackage | null>(null);
  const [attribute, setAttribute] = useState(prefill?.attribute ?? '');
  const [attributeLabel, setAttributeLabel] = useState(prefill?.attribute ?? '');
  const [display, setDisplay] = useState<AttributeDisplay>(prefill?.display ?? 'value');
  const [notice, setNotice] = useState<string | null>(null);

  const prefilledId = !picked && prefill ? Number(prefill.wpid) : undefined;
  const { workPackage: prefilledWorkPackage } = useWorkPackage(prefilledId);
  const workPackage = picked ?? prefilledWorkPackage;
  const { schema } = useWorkPackageSchema(workPackage?._links?.schema?.href);

  const attributes = useMemo(() => (schema ? listAttributes(schema) : []), [schema]);
  const selected = schema && attribute ? findAttribute(schema, attribute) : undefined;

  // A newly picked work package may not offer what the previous one did.
  useEffect(() => {
    if (!schema || !attribute || findAttribute(schema, attribute) || !workPackage) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNotice(t('workPackageAttribute.dialog.notAvailable', {
      attribute: attributeLabel,
      id: formatWorkPackageId(workPackage.displayId),
    }));
    setAttribute('');
  }, [schema, attribute, attributeLabel, workPackage, t]);

  useEffect(() => { panelRef.current?.focus(); }, []);

  const pickWorkPackage = (chosen:WorkPackage) => {
    setPicked(chosen);
    setNotice(null);
  };

  const insert = () => {
    if (!workPackage || !selected) return;
    onInsert({
      wpid: String(workPackage.id),
      displayId: workPackage.displayId,
      attribute: selected.reference,
      display,
    });
  };

  const attributeControl = workPackage && schema
    ? (
      <AllowedValuesSelect
        id={ATTRIBUTE_CONTROL_ID}
        label={t('workPackageAttribute.dialog.attribute')}
        options={attributes.map((option) => ({ href: option.reference, label: option.label }))}
        value={selected?.reference ?? ''}
        placeholder={t('workPackageAttribute.dialog.attributePlaceholder')}
        onChange={(reference) => {
          setAttribute(reference);
          setAttributeLabel(attributes.find((option) => option.reference === reference)?.label ?? reference);
          setNotice(null);
        }}
      />
    )
    : (
      <DisabledControl
        id={ATTRIBUTE_CONTROL_ID}
        disabled
        readOnly
        placeholder={workPackage
          ? t('workPackageAttribute.dialog.attributeLoading')
          : t('workPackageAttribute.dialog.attributeDisabled')}
      />
    );

  return (
    <FullPagePortal anchorEl={anchorEl} carriedVariables={EDITOR_VARIABLES}>
      <Overlay onMouseDown={onCancel}>
        <Panel
          ref={panelRef}
          tabIndex={-1}
          aria-label={t('workPackageAttribute.dialog.title')}
          onMouseDown={(event) => event.stopPropagation()}
          onKeyDown={(event) => {
            event.stopPropagation();
            if (event.key === 'Escape') onCancel();
            if (event.key === 'Tab') keepFocusInside(panelRef.current, event);
          }}
        >
          <Header>
            <HeaderTitle>{t('workPackageAttribute.dialog.title')}</HeaderTitle>
            <IconButton type="button" aria-label={t('createWorkPackage.close')} onClick={onCancel}>
              <XIcon size={16} />
            </IconButton>
          </Header>

          <Body>
            <BodyContent>
              <FieldRow>
                <FieldLabel htmlFor={WORK_PACKAGE_CONTROL_ID}>
                  {t('workPackageAttribute.dialog.workPackage')}
                  <RequiredMark> *</RequiredMark>
                </FieldLabel>
                <WorkPackagePicker
                  id={WORK_PACKAGE_CONTROL_ID}
                  label={t('workPackageAttribute.dialog.workPackage')}
                  selected={workPackage}
                  autoFocus={!prefill}
                  onPick={pickWorkPackage}
                  onEscape={onCancel}
                />
              </FieldRow>

              <FieldRow>
                <AttributeLabel htmlFor={ATTRIBUTE_CONTROL_ID} $disabled={!workPackage}>
                  {t('workPackageAttribute.dialog.attribute')}
                  <RequiredMark> *</RequiredMark>
                </AttributeLabel>
                {attributeControl}
                {notice && (
                  <FieldHint role="status">
                    <AlertIcon size={14} />
                    <span>{notice}</span>
                  </FieldHint>
                )}
              </FieldRow>

              <FieldRow>
                <FieldLabel as="div" id={`${ATTRIBUTE_CONTROL_ID}-show`}>
                  {t('workPackageAttribute.dialog.show')}
                </FieldLabel>
                <DisplayOptions aria-labelledby={`${ATTRIBUTE_CONTROL_ID}-show`}>
                  {DISPLAYS.map((option) => (
                    <DisplayOption
                      key={option}
                      $active={display === option}
                      aria-checked={display === option}
                      onClick={() => setDisplay(option)}
                    >
                      {t(`workPackageAttribute.display.${option}`)}
                    </DisplayOption>
                  ))}
                </DisplayOptions>
              </FieldRow>

              <PreviewLabel>{t('workPackageAttribute.dialog.preview')}</PreviewLabel>
              <PreviewBox data-testid="insert-attribute-preview">
                {workPackage && selected
                  ? (
                    <AttributeChipSurface>
                      <WorkPackageAttributeView
                        resolved={{
                          state: 'ready',
                          workPackage,
                          attribute: selected,
                          value: formatAttributeValue(workPackage, selected, formatOptions),
                        }}
                        display={display}
                        reference={selected.reference}
                      />
                    </AttributeChipSurface>
                  )
                  : <PreviewPlaceholder>{t('workPackageAttribute.dialog.previewEmpty')}</PreviewPlaceholder>}
              </PreviewBox>
            </BodyContent>
          </Body>

          <Footer>
            <Button type="button" onClick={onCancel}>{t('createWorkPackage.cancel')}</Button>
            <Button
              type="button"
              $primary
              data-testid="insert-attribute-submit"
              disabled={!workPackage || !selected}
              onClick={insert}
            >
              {t('workPackageAttribute.dialog.insert')}
            </Button>
          </Footer>
        </Panel>
      </Overlay>
    </FullPagePortal>
  );
};
