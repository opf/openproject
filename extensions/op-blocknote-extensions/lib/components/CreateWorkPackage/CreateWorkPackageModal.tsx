import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { StyleSheetManager } from 'styled-components';
import { useTranslation } from 'react-i18next';
import { AlertIcon, SyncIcon, XIcon } from '@primer/octicons-react';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToNewWorkPackage } from '../../services/openProjectApi';
import { projectIdFromHref } from '../../utils/id';
import { dependencyOf } from './formSchema';
import type { FormField } from './formSchema';
import { FormFieldControl } from './FormFieldControl';
import { useCreateWorkPackageForm } from './useCreateWorkPackageForm';
import {
  Body,
  Button,
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
  SectionLabel,
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

const FullPagePortal = ({ colorScheme, children }:{ colorScheme?:string; children:React.ReactNode }) => createPortal(
  <StyleSheetManager target={document.head}>
    <div data-color-scheme={colorScheme}>{children}</div>
  </StyleSheetManager>,
  document.body
);

function colorSchemeOf(anchorEl?:HTMLElement | null):string | undefined {
  return anchorEl?.closest('[data-color-scheme]')?.getAttribute('data-color-scheme') ?? undefined;
}

// The page behind the modal must not move; what scrolls is the form itself. Only
// the body has to be held: the modal is portalled out of the editor, so nothing
// the editor scrolls is an ancestor of it any more.
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
  // Element the modal was opened from; the theme is read from it.
  anchorEl?:HTMLElement | null;
  onCreated:(workPackage:WorkPackage) => void;
  onCancel:() => void;
}

export const CreateWorkPackageModal = ({ anchorEl, onCreated, onCancel }:CreateWorkPackageModalProps) => {
  const { t } = useTranslation();
  const panelRef = useRef<HTMLDivElement>(null);
  usePageScrollLock();
  const {
    primaryFields,
    extraFields,
    values,
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
    unsupportedFields,
    canSubmit,
    submit,
  } = useCreateWorkPackageForm(onCreated);

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
      autoFocus={field.key === 'subject'}
      onChange={(value) => setValue(field.key, value)}
    />
  );

  return (
    <FullPagePortal colorScheme={colorSchemeOf(anchorEl)}>
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
              if (canSubmit) submit();
            }}
          >
            <Body>
              {notAllowed && <Alert>{t('createWorkPackage.notAllowed')}</Alert>}

              {loadError && <Alert>{t('createWorkPackage.loadFailed', { message: loadError })}</Alert>}

              {submitError && <Alert data-testid="create-wp-error">{submitError}</Alert>}

              {primaryFields.map(renderField)}

              {loading && (
                <LoadingRow>
                  <Spinner><SyncIcon size={14} /></Spinner>
                  {selectedTypeLabel
                    ? t('createWorkPackage.loadingTypeFields', { type: selectedTypeLabel })
                    : t('createWorkPackage.loadingFields')}
                </LoadingRow>
              )}

              {extraFields.length > 0 && (
                <>
                  <SectionLabel>{t('createWorkPackage.requiredFields')}</SectionLabel>
                  {extraFields.map(renderField)}
                </>
              )}

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
                disabled={!canSubmit}
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
