import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { StyleSheetManager } from 'styled-components';
import { useTranslation } from 'react-i18next';
import { AlertIcon, SyncIcon, XIcon } from '@primer/octicons-react';
import type { WorkPackage } from '../../openProjectTypes';
import { useColors } from '../../services/colors';
import { linkToNewWorkPackage } from '../../services/openProjectApi';
import { projectIdFromHref } from '../../utils/id';
import { dependencyOf } from './formSchema';
import type { FormField } from './formSchema';
import { FormFieldControl } from './FormFieldControl';
import { useCreateWorkPackageForm } from './useCreateWorkPackageForm';
import {
  Body,
  Button,
  Divider,
  Footer,
  Form,
  Header,
  HeaderTitle,
  IconButton,
  LoadingRow,
  Notice,
  NoticeLink,
  Overlay,
  Panel,
  Spinner,
} from './atoms';

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
].join(', ');

const Alert = ({ children, ...rest }:{ children:React.ReactNode } & React.ComponentProps<typeof Notice>) => (
  <Notice $error {...rest}>
    <AlertIcon size={14} />
    <span>{children}</span>
  </Notice>
);

interface FullPagePortalProps {
  colorScheme?:string;
  fontFamily?:string;
  children:React.ReactNode;
}

const FullPagePortal = ({ colorScheme, fontFamily, children }:FullPagePortalProps) => createPortal(
  <StyleSheetManager target={document.head}>
    <div
      data-color-scheme={colorScheme}
      style={{ '--bn-font-family': fontFamily } as React.CSSProperties}
    >
      {children}
    </div>
  </StyleSheetManager>,
  document.body
);

function colorSchemeOf(anchorEl?:HTMLElement | null):string | undefined {
  return anchorEl?.closest('[data-color-scheme]')?.getAttribute('data-color-scheme') ?? undefined;
}

// BlockNote declares its font on ".bn-root", which the portal leaves behind.
function fontFamilyOf(anchorEl?:HTMLElement | null):string | undefined {
  if (!anchorEl) return undefined;
  return getComputedStyle(anchorEl).getPropertyValue('--bn-font-family').trim() || undefined;
}

// Only the body has to be held: the modal is portalled out of the editor, so
// nothing the editor scrolls is an ancestor of it any more.
function usePageScrollLock():void {
  useEffect(() => {
    const { style } = document.body;
    const previous = { overflow: style.overflow, paddingRight: style.paddingRight };
    // Room the scrollbar leaves behind, so the page does not jump sideways.
    const scrollbar = window.innerWidth - document.documentElement.clientWidth;

    style.overflow = 'hidden';
    if (scrollbar > 0) style.paddingRight = `${scrollbar}px`;

    return () => {
      style.overflow = previous.overflow;
      style.paddingRight = previous.paddingRight;
    };
  }, []);
}

function keepFocusInside(panel:HTMLElement | null, event:React.KeyboardEvent):void {
  if (!panel) return;

  const focusable = Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR))
    .filter((element) => element.offsetParent !== null);
  if (focusable.length === 0) return;

  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  const root = panel.getRootNode() as Document | ShadowRoot;

  if (event.shiftKey && root.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && root.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

export interface CreateWorkPackageModalProps {
  anchorEl?:HTMLElement | null;
  onCreated:(workPackage:WorkPackage) => void;
  onCancel:() => void;
}

export const CreateWorkPackageModal = ({ anchorEl, onCreated, onCancel }:CreateWorkPackageModalProps) => {
  const { t } = useTranslation();
  const panelRef = useRef<HTMLDivElement>(null);
  usePageScrollLock();
  useColors();
  const {
    primaryFields,
    extraFields,
    values,
    valueLabels,
    setValue,
    projectHref,
    typeHref,
    isDirty,
    selectedTypeLabel,
    loading,
    loadError,
    notAllowed,
    submitting,
    submitError,
    fieldErrors,
    valueProblems,
    unsupportedFields,
    submitEnabled,
    attemptSubmit,
  } = useCreateWorkPackageForm(onCreated);

  const showField = (key:string) => {
    const control = panelRef.current?.querySelector<HTMLElement>(`[id="op-bn-create-wp-${key}"]`);
    control?.focus();
    control?.scrollIntoView({ block: 'nearest' });
  };

  // A long form scrolls the message on top out of view, so it only points down.
  const formError = [
    Object.keys(fieldErrors).length > 0 ? t('createWorkPackage.validationFailed') : null,
    submitError,
  ].filter(Boolean).join(' ');

  // Remounts a control when the selection its values came from changes.
  const keyOf = (key:string) => {
    const dependsOn = dependencyOf(key);
    if (!dependsOn) return key;
    return dependsOn === 'project' ? `${key}:${projectHref}` : `${key}:${projectHref}:${typeHref}`;
  };

  const renderField = (field:FormField) => (
    <FormFieldControl
      key={keyOf(field.key)}
      field={field}
      value={values[field.key]}
      valueLabel={valueLabels[field.key]}
      autoFocus={field.key === 'subject'}
      error={fieldErrors[field.key]}
      problem={valueProblems[field.key]}
      onChange={(value, label) => setValue(field.key, value, label)}
    />
  );

  return (
    <FullPagePortal colorScheme={colorSchemeOf(anchorEl)} fontFamily={fontFamilyOf(anchorEl)}>
      <Overlay
        onMouseDown={() => { if (!isDirty) onCancel(); }}
      >
        <Panel
          ref={panelRef}
          aria-label={t('createWorkPackage.title')}
          onMouseDown={(event) => event.stopPropagation()}
          onKeyDown={(event) => {
            event.stopPropagation();
            if (event.key === 'Escape') onCancel();
            if (event.key === 'Tab') keepFocusInside(panelRef.current, event);
          }}
        >
          <Header>
            <HeaderTitle>{t('createWorkPackage.title')}</HeaderTitle>
            <IconButton type="button" aria-label={t('createWorkPackage.close')} onClick={onCancel}>
              <XIcon size={16} />
            </IconButton>
          </Header>

          <Form
            onSubmit={(event) => {
              event.preventDefault();
              if (!submitEnabled) return;

              const blocking = attemptSubmit();
              if (blocking) showField(blocking);
            }}
          >
            <Body>
              {notAllowed && <Alert>{t('createWorkPackage.notAllowed')}</Alert>}

              {loadError && <Alert>{t('createWorkPackage.loadFailed', { message: loadError })}</Alert>}

              {formError && <Alert data-testid="create-wp-error">{formError}</Alert>}

              {primaryFields.map(renderField)}

              {loading && (
                <LoadingRow>
                  <Spinner><SyncIcon size={14} /></Spinner>
                  {selectedTypeLabel
                    ? t('createWorkPackage.loadingTypeFields', { type: selectedTypeLabel })
                    : t('createWorkPackage.loadingFields')}
                </LoadingRow>
              )}

              {extraFields.length > 0 && <Divider data-testid="create-wp-divider" />}

              {extraFields.map(renderField)}

              {unsupportedFields.length > 0 && (
                <Notice>
                  <AlertIcon size={14} />
                  <span>
                    {t('createWorkPackage.unsupportedRequired')}{' '}
                    <NoticeLink
                      href={linkToNewWorkPackage(projectIdFromHref(projectHref))}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {t('createWorkPackage.createInOpenProject')}
                    </NoticeLink>
                  </span>
                </Notice>
              )}
            </Body>

            <Footer>
              <Button type="button" onClick={onCancel}>{t('createWorkPackage.cancel')}</Button>
              <Button
                type="submit"
                $primary
                data-testid="create-wp-submit"
                disabled={!submitEnabled}
              >
                {submitting ? t('createWorkPackage.creating') : t('createWorkPackage.create')}
              </Button>
            </Footer>
          </Form>
        </Panel>
      </Overlay>
    </FullPagePortal>
  );
};
