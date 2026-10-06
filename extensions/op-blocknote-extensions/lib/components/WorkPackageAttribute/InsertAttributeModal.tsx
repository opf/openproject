import { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertIcon, HistoryIcon, XIcon } from '@primer/octicons-react';
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
  RequiredMark,
} from '../CreateWorkPackage/atoms';
import { findAttribute, formatAttributeValue, listAttributes } from './attributes';
import type { AttributeDisplay } from './externalHtml';
import type { AttributeChoice } from './pending';
import { WorkPackageAttributeView } from './WorkPackageAttributeView';
import { useAttributeFormatOptions } from './useWorkPackageAttribute';
import { WorkPackagePicker } from './WorkPackagePicker';
import {
  AttributeChipSurface,
  AttributeFieldLabel,
  AttributePanel,
  DisabledControl,
  DisplayOption,
  DisplayOptions,
  LinkButton,
  PrefillNote,
  PreviewBox,
  PreviewLabel,
  PreviewPlaceholder,
} from './atoms';

const ATTRIBUTE_CONTROL_ID = 'op-bn-wp-attribute-select';
const WORK_PACKAGE_CONTROL_ID = 'op-bn-wp-attribute-work-package';
const DISPLAY_LABEL_ID = 'op-bn-wp-attribute-display';

// What the chip in the preview is drawn with.
const EDITOR_VARIABLES = [
  '--bn-colors-editor-text',
  '--bn-colors-editor-background',
  '--bn-border-radius',
];

const DISPLAYS:AttributeDisplay[] = ['label', 'value', 'both'];

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

  const [prefilled, setPrefilled] = useState(prefill);
  const [picked, setPicked] = useState<WorkPackage | null>(null);
  const [attribute, setAttribute] = useState(prefill?.attribute ?? '');
  const [attributeLabel, setAttributeLabel] = useState(prefill?.attribute ?? '');
  const [display, setDisplay] = useState<AttributeDisplay>(prefill?.display ?? 'value');
  const [notice, setNotice] = useState<string | null>(null);

  const prefilledId = !picked && prefilled ? Number(prefilled.wpid) : undefined;
  const { workPackage: prefilledWorkPackage } = useWorkPackage(prefilledId);
  const workPackage = picked ?? prefilledWorkPackage;
  const { schema, error: schemaError, retry: retrySchema } = useWorkPackageSchema(workPackage?._links?.schema?.href);

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

  const clearPrefill = () => {
    setPrefilled(undefined);
    setPicked(null);
    setAttribute('');
    setDisplay('value');
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
        placeholder={!workPackage
          ? t('workPackageAttribute.dialog.attributeDisabled')
          : t(schemaError ? 'workPackageAttribute.dialog.attributeUnavailable' : 'workPackageAttribute.dialog.attributeLoading')}
      />
    );

  return (
    <FullPagePortal anchorEl={anchorEl} carriedVariables={EDITOR_VARIABLES}>
      <Overlay onMouseDown={onCancel}>
        <AttributePanel
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
              {prefilled && (
                <PrefillNote>
                  <span>
                    <HistoryIcon size={14} />
                    {t('workPackageAttribute.dialog.prefilled')}
                  </span>
                  <LinkButton onClick={clearPrefill}>{t('createWorkPackage.clear')}</LinkButton>
                </PrefillNote>
              )}

              <FieldRow>
                <FieldLabel htmlFor={WORK_PACKAGE_CONTROL_ID}>
                  {t('workPackageAttribute.dialog.workPackage')}
                  <RequiredMark> *</RequiredMark>
                </FieldLabel>
                <WorkPackagePicker
                  id={WORK_PACKAGE_CONTROL_ID}
                  label={t('workPackageAttribute.dialog.workPackage')}
                  selected={workPackage}
                  autoFocus={!prefilled}
                  onPick={pickWorkPackage}
                  onEscape={onCancel}
                />
              </FieldRow>

              <FieldRow>
                <AttributeFieldLabel htmlFor={ATTRIBUTE_CONTROL_ID} $disabled={!workPackage}>
                  {t('workPackageAttribute.dialog.attribute')}
                  <RequiredMark> *</RequiredMark>
                </AttributeFieldLabel>
                {attributeControl}
                {workPackage && schemaError && (
                  <FieldHint $error role="alert">
                    <AlertIcon size={14} />
                    <span>
                      {t('workPackageAttribute.dialog.loadFailed', { id: formatWorkPackageId(workPackage.displayId) })}{' '}
                      <LinkButton onClick={retrySchema}>{t('workPackageAttribute.dialog.retry')}</LinkButton>
                    </span>
                  </FieldHint>
                )}
                {notice && (
                  <FieldHint role="status">
                    <AlertIcon size={14} />
                    <span>{notice}</span>
                  </FieldHint>
                )}
              </FieldRow>

              <FieldRow>
                <FieldLabel as="div" id={DISPLAY_LABEL_ID}>
                  {t('workPackageAttribute.dialog.show')}
                </FieldLabel>
                <DisplayOptions aria-labelledby={DISPLAY_LABEL_ID}>
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
              disabled={!workPackage || !selected}
              onClick={insert}
            >
              {t('workPackageAttribute.dialog.insert')}
            </Button>
          </Footer>
        </AttributePanel>
      </Overlay>
    </FullPagePortal>
  );
};
