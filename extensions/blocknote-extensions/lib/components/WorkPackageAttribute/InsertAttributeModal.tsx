import { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertIcon, HistoryIcon } from '@primer/octicons-react';
import type { WorkPackage } from '../../openProjectTypes';
import { useColors } from '../../services/colors';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { cachedWorkPackageSchema } from '../../services/workPackageLoader';
import { formatWorkPackageId } from '../../utils/id';
import { Modal } from '../Shared/modal';
import { Button } from '../Shared/Button';
import { AllowedValuesSelect } from '../Shared/AllowedValuesSelect';
import {
  Body,
  BodyContent,
  FieldHint,
  FieldLabel,
  FieldRow,
  Footer,
  RequiredMark,
} from '../Shared/atoms';
import { findAttribute, formatAttributeValue, listAttributes, type WorkPackageAttribute } from './attributes';
import type { AttributeNodeKind } from './externalHtml';
import { ATTRIBUTE_DISPLAYS, DEFAULT_ATTRIBUTE_DISPLAY, type AttributeDisplay } from './display';
import type { AttributeChoice } from './types';
import { WorkPackageAttributeBlockView, WorkPackageAttributeView } from './WorkPackageAttributeView';
import { useAttributeFormatOptions, type ReadyAttribute } from './useWorkPackageAttribute';
import { WorkPackagePicker } from './WorkPackagePicker';
import {
  AttributeSurface,
  AttributeFieldLabel,
  BlockPreview,
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

const PREVIEW_EDITOR_VARIABLES = [
  '--bn-colors-editor-text',
  '--bn-colors-editor-background',
  '--bn-colors-highlights-gray-text',
  '--bn-border-radius',
];

const isOffered = (attribute:WorkPackageAttribute, offersLongText:boolean) => offersLongText || !attribute.block;

const AttributePreview = ({ resolved, display }:{ resolved:ReadyAttribute, display:AttributeDisplay }) => {
  const view = { resolved, display, reference: resolved.attribute.reference };
  return resolved.attribute.block
    ? <BlockPreview><WorkPackageAttributeBlockView {...view} /></BlockPreview>
    : <AttributeSurface><WorkPackageAttributeView {...view} /></AttributeSurface>;
};

export interface InsertAttributeModalProps {
  anchorEl?:HTMLElement | null;
  prefill?:AttributeChoice;
  // Long text needs the block spec, which an editor may not have registered.
  offersLongText:boolean;
  onInsert:(choice:AttributeChoice, kind:AttributeNodeKind) => void;
  onCancel:() => void;
}

export const InsertAttributeModal = ({ anchorEl, prefill, offersLongText, onInsert, onCancel }:InsertAttributeModalProps) => {
  const { t } = useTranslation();
  const panelRef = useRef<HTMLDivElement>(null);
  useColors();
  const formatOptions = useAttributeFormatOptions();

  const [prefilled, setPrefilled] = useState(prefill);
  const [picked, setPicked] = useState<WorkPackage | null>(null);
  const [attribute, setAttribute] = useState(prefill?.attribute ?? '');
  const [attributeLabel, setAttributeLabel] = useState(prefill?.attribute ?? '');
  const [display, setDisplay] = useState<AttributeDisplay>(prefill?.display ?? DEFAULT_ATTRIBUTE_DISPLAY);
  const [notice, setNotice] = useState<string | null>(null);
  const [touched, setTouched] = useState(false);

  const prefilledId = !picked && prefilled ? Number(prefilled.wpid) : undefined;
  const wantedId = picked?.id ?? prefilledId;
  // Loaded even when picked: the schema comes embedded with the loaded work package.
  const {
    workPackage: loaded,
    unauthorized,
    error,
    retry: retrySchema,
  } = useWorkPackage(wantedId);
  // Until the load of another work package settles, the hook still holds the previous one.
  const loadedWanted = loaded && loaded.id === wantedId ? loaded : null;
  const workPackage = picked ?? loadedWanted;
  const schema = loadedWanted ? cachedWorkPackageSchema(loadedWanted) : undefined;
  const schemaError = unauthorized || !!error || (!!loadedWanted && !schema);
  // What was prefilled is nothing the user would miss.
  const isDirty = touched && (wantedId !== undefined || attribute !== '' || display !== DEFAULT_ATTRIBUTE_DISPLAY);

  const attributes = useMemo(
    () => (schema ? listAttributes(schema).filter((option) => isOffered(option, offersLongText)) : []),
    [schema, offersLongText],
  );
  const found = schema && attribute ? findAttribute(schema, attribute) : undefined;
  const selected = found && isOffered(found, offersLongText) ? found : undefined;

  useEffect(() => {
    if (!schema || !attribute || findAttribute(schema, attribute) || !workPackage) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNotice(t('workPackageAttribute.dialog.notAvailable', {
      attribute: attributeLabel,
      id: formatWorkPackageId(workPackage.displayId),
    }));
    setAttribute('');
  }, [schema, attribute, attributeLabel, workPackage, t]);

  const pickWorkPackage = (chosen:WorkPackage) => {
    setTouched(true);
    setPicked(chosen);
    setNotice(null);
  };

  const deselectWorkPackage = () => {
    setTouched(true);
    setPrefilled(undefined);
    setPicked(null);
    setNotice(null);
  };

  const clearPrefill = () => {
    deselectWorkPackage();
    setAttribute('');
    setDisplay(DEFAULT_ATTRIBUTE_DISPLAY);
  };

  const insert = () => {
    if (!workPackage || !selected) return;
    onInsert({
      wpid: String(workPackage.id),
      displayId: workPackage.displayId,
      attribute: selected.reference,
      display,
    }, selected.block ? 'block' : 'inline');
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
          setTouched(true);
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
    <Modal
      anchorEl={anchorEl}
      carriedVariables={PREVIEW_EDITOR_VARIABLES}
      panelRef={panelRef}
      title={t('workPackageAttribute.dialog.title')}
      dismissible={!isDirty}
      onCancel={onCancel}
    >
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
              onDeselect={deselectWorkPackage}
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
              {ATTRIBUTE_DISPLAYS.map((option) => (
                <DisplayOption
                  key={option}
                  $active={display === option}
                  aria-checked={display === option}
                  onClick={() => {
                    setTouched(true);
                    setDisplay(option);
                  }}
                >
                  {t(`workPackageAttribute.display.${option}`)}
                </DisplayOption>
              ))}
            </DisplayOptions>
          </FieldRow>

          <PreviewLabel>{t('workPackageAttribute.dialog.preview')}</PreviewLabel>
          <PreviewBox data-testid="insert-attribute-preview">
            {workPackage && selected && formatOptions
              ? (
                <AttributePreview
                  resolved={{
                    state: 'ready',
                    workPackage,
                    attribute: selected,
                    value: formatAttributeValue(workPackage, selected, formatOptions),
                  }}
                  display={display}
                />
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
    </Modal>
  );
};
