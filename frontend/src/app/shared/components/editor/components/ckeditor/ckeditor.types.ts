import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  ICKEditorMacroType,
  ICKEditorType,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import type {
  CKEditorDomEventData,
  CKEditorEvent,
  CKEditorListenOptions,
  ICKEditorContext as ICKEditorBuildContext,
  ICKEditorError,
  ICKEditorInstance,
  ICKEditorStatic,
  ICKEditorState,
  ICKEditorWatchdog,
} from 'core-vendor/ckeditor/types';

export type {
  CKEditorDomEventData,
  CKEditorEvent,
  CKEditorListenOptions,
  ICKEditorError,
  ICKEditorInstance,
  ICKEditorStatic,
  ICKEditorState,
  ICKEditorWatchdog,
};

export interface ICKEditorContext extends Omit<ICKEditorBuildContext, 'resource'|'macros'> {
  // Editor type to setup
  type:ICKEditorType;
  // Hal Resource to pass into ckeditor
  resource?:HalResource;
  // If available, field name of the edit
  field?:string;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all.
  macros?:ICKEditorMacroType;
}

declare global {
  interface HTMLElement {
    ckeditorInstance?:ICKEditorInstance;
  }
}
