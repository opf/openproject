//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Excalidraw, Footer, MainMenu } from '@excalidraw/excalidraw';
import type { OrderedExcalidrawElement, Theme } from '@excalidraw/excalidraw/element/types';
import type {
  AppState,
  Collaborator,
  ExcalidrawImperativeAPI,
  ExcalidrawInitialDataState,
} from '@excalidraw/excalidraw/types';
import type { HocuspocusProvider, onStatelessParameters } from '@hocuspocus/provider';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useCollaboration } from '../hooks/useCollaboration';
import { ExcalidrawYjsBinding } from './excalidraw-yjs-binding';
import { WhiteboardAwareness, type WhiteboardUser } from './whiteboard-awareness';

export interface OpWhiteboardProps {
  provider:HocuspocusProvider;
  user:WhiteboardUser;
  readOnly:boolean;
  title:string;
  leaveUrl:string;
  langCode:string;
}

const t = (key:string) => window.I18n.t(`js.whiteboards.${key}`);

function currentOpTheme():Theme {
  return document.body.dataset.colorMode === 'dark' ? 'dark' : 'light';
}

function useOpTheme():Theme {
  const [theme, setTheme] = useState(currentOpTheme);

  useEffect(() => {
    const update = () => setTheme(currentOpTheme());
    window.addEventListener('op:theme-changed', update);
    return () => window.removeEventListener('op:theme-changed', update);
  }, []);

  return theme;
}

function LeaveButton({ leaveUrl }:{ leaveUrl:string }) {
  return (
    <a
      className="op-whiteboard-chrome--leave"
      href={leaveUrl}
      aria-label={t('leave')}
      title={t('leave')}
      data-test-selector="whiteboard-leave"
    >
      <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
        <path d="M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.749.749 0 0 1 1.275.326.749.749 0 0 1-.215.734L9.06 8l3.22 3.22a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215L8 9.06l-3.22 3.22a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06Z" />
      </svg>
    </a>
  );
}

type SaveState = { kind:'saved'; at:Date|null } | { kind:'saving' } | { kind:'delayed' };

const SAVE_DELAYED_AFTER_MS = 20_000;

function useSaveState(provider:HocuspocusProvider):SaveState {
  const [state, setState] = useState<SaveState>({ kind: 'saved', at: null });

  useEffect(() => {
    let delayTimer:ReturnType<typeof setTimeout>|null = null;
    const clearDelayTimer = () => {
      if (delayTimer !== null) clearTimeout(delayTimer);
      delayTimer = null;
    };

    const onUpdate = () => {
      setState((current) => (current.kind === 'delayed' ? current : { kind: 'saving' }));
      delayTimer ??= setTimeout(() => setState({ kind: 'delayed' }), SAVE_DELAYED_AFTER_MS);
    };
    const onStateless = ({ payload }:onStatelessParameters) => {
      if (payload !== 'storeEvent') return;
      clearDelayTimer();
      setState({ kind: 'saved', at: new Date() });
    };
    const warnAboutUnsentChanges = (event:BeforeUnloadEvent) => {
      if (provider.hasUnsyncedChanges) event.preventDefault();
    };

    provider.document.on('update', onUpdate);
    provider.on('stateless', onStateless);
    window.addEventListener('beforeunload', warnAboutUnsentChanges);

    return () => {
      clearDelayTimer();
      provider.document.off('update', onUpdate);
      provider.off('stateless', onStateless);
      window.removeEventListener('beforeunload', warnAboutUnsentChanges);
    };
  }, [provider]);

  return state;
}

function saveStateLabel(state:SaveState):string {
  if (state.kind === 'saving') return t('save.saving');
  if (state.kind === 'delayed') return t('save.delayed');
  if (!state.at) return t('save.saved');

  const time = state.at.toLocaleTimeString(window.I18n.locale, { hour: '2-digit', minute: '2-digit' });
  return window.I18n.t('js.whiteboards.save.saved_at', { time });
}

function ConnectionStatus({ offline, saveState }:{ offline:boolean; saveState:SaveState }) {
  const state = offline ? 'offline' : saveState.kind;
  return (
    <span className={`op-whiteboard-chrome--status op-whiteboard-chrome--status_${state}`} data-test-selector="whiteboard-connection-status">
      {offline ? t('connection.offline') : saveStateLabel(saveState)}
    </span>
  );
}

function WhiteboardCanvas({ provider, user, readOnly, title, leaveUrl, langCode, offline }:OpWhiteboardProps & { offline:boolean }) {
  const doc = provider.document;
  const [api, setApi] = useState<ExcalidrawImperativeAPI|null>(null);
  const bindingRef = useRef<ExcalidrawYjsBinding|null>(null);
  const awarenessRef = useRef<WhiteboardAwareness|null>(null);
  const saveState = useSaveState(provider);
  const theme = useOpTheme();

  const initialData = useMemo<ExcalidrawInitialDataState>(
    () => ({ elements: ExcalidrawYjsBinding.storedElements(doc), scrollToContent: true }),
    [doc],
  );

  useEffect(() => {
    if (!api) return undefined;

    const binding = new ExcalidrawYjsBinding(doc, api, readOnly);
    const awareness = new WhiteboardAwareness(provider, user, (collaborators) => api.updateScene({ collaborators }));
    bindingRef.current = binding;
    awarenessRef.current = awareness;

    return () => {
      binding.destroy();
      awareness.destroy();
      bindingRef.current = null;
      awarenessRef.current = null;
    };
  }, [api, doc, provider, readOnly, user]);

  const onChange = useCallback((elements:readonly OrderedExcalidrawElement[], appState:AppState) => {
    bindingRef.current?.onSceneChange(elements);
    awarenessRef.current?.updateSelection(appState.selectedElementIds);
  }, []);

  const onPointerUpdate = useCallback(
    ({ pointer, button }:{ pointer:NonNullable<Collaborator['pointer']>; button:Collaborator['button'] }) => {
      awarenessRef.current?.updatePointer(pointer, button);
    },
    [],
  );

  const renderTopRightUI = useCallback(() => (
    <div className="op-whiteboard-chrome">
      <LeaveButton leaveUrl={leaveUrl} />
    </div>
  ), [leaveUrl]);

  return (
    <Excalidraw
      excalidrawAPI={setApi}
      initialData={initialData}
      onChange={onChange}
      onPointerUpdate={onPointerUpdate}
      isCollaborating
      viewModeEnabled={readOnly || offline}
      langCode={langCode}
      theme={theme}
      name={title}
      renderTopRightUI={renderTopRightUI}
      UIOptions={{
        canvasActions: { loadScene: false, saveToActiveFile: false, clearCanvas: !readOnly, toggleTheme: false },
        tools: { image: false },
      }}
    >
      <MainMenu>
        <MainMenu.ItemLink href={leaveUrl}>{t('leave')}</MainMenu.ItemLink>
        <MainMenu.Separator />
        <MainMenu.DefaultItems.SaveAsImage />
        <MainMenu.DefaultItems.SearchMenu />
        <MainMenu.DefaultItems.Help />
        {!readOnly && <MainMenu.DefaultItems.ClearCanvas />}
        <MainMenu.Separator />
        <MainMenu.DefaultItems.ChangeCanvasBackground />
      </MainMenu>
      <Footer>
        <ConnectionStatus offline={offline} saveState={saveState} />
      </Footer>
    </Excalidraw>
  );
}

export default function OpWhiteboard(props:OpWhiteboardProps) {
  const { isLoading, offlineMode } = useCollaboration(props.provider);

  if (isLoading) {
    return <div className="op-whiteboard--loading">{t('connection.connecting')}</div>;
  }

  return <WhiteboardCanvas {...props} offline={offlineMode} />;
}
