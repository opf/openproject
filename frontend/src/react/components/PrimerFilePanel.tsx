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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { FilePanelExtension } from '@blocknote/core/extensions';
import { ArrowSwitchIcon } from '@primer/octicons-react';
import {
  ComponentProps, ComponentsContext, EmbedTab, FilePanelController, FilePanelProps,
  preventFocusOnTap, useBlockNoteEditor, useComponentsContext, useDictionary, useEditorState, useExtension,
} from '@blocknote/react';
import { Button, FormControl, IconButton, Spinner, TextInput } from '@primer/react';
import { UnderlinePanels } from '@primer/react/experimental';
import { useEffect, useMemo, useRef, useState } from 'react';

type Panel = ComponentProps['FilePanel'];

function MediaPanel({ blockId }:FilePanelProps) {
  const editor = useBlockNoteEditor();
  const dict = useDictionary().file_panel;
  const [tab, setTab] = useState(dict.upload.title);
  const [uploadState, setUploadState] = useState<'idle' | 'loading' | 'failed'>('idle');
  const block = editor.getBlock(blockId);
  const panelRef = useRef<HTMLDivElement>(null);
  const replacing = !!block && 'url' in block.props && !!block.props.url;
  useEffect(() => {
    if (replacing) panelRef.current?.querySelector<HTMLElement>('[role="tab"][aria-selected="true"], input:not([type="file"])')?.focus({ preventScroll: true });
  }, [blockId, replacing]);
  if (!block) return null;

  const embed = <EmbedTab blockId={blockId} />;
  const { uploadFile } = editor;
  if (!uploadFile) return <div ref={panelRef} className="op-blocknote-file-panel">{embed}</div>;

  const types = editor.schema.blockSpecs[block.type].implementation.meta?.fileBlockAccept;
  const placeholder = dict.upload.file_placeholder[block.type] ?? dict.upload.file_placeholder.file;
  const loading = uploadState === 'loading';
  const upload = async (file:File | null) => {
    if (!file) return;
    setUploadState('loading');
    try {
      // With a block ID, BlockNote replaces its add-file button until a successful update (SE-661).
      const result = await uploadFile(file);
      if (!result) {
        setUploadState('failed');
        return;
      }
      if (editor.getBlock(blockId)) {
        editor.updateBlock(blockId, typeof result === 'string' ? { props: { name: file.name, url: result } } : result);
      }
      setUploadState('idle');
    } catch {
      setUploadState('failed');
    }
  };
  return (
    <div ref={panelRef} className="op-blocknote-file-panel" aria-busy={loading}>
      <div inert={loading}>
        <UnderlinePanels aria-label={window.I18n.t('js.blocknote.file_source')} value={tab} onChange={({ value }) => setTab(value)}>
          {[dict.upload.title, dict.embed.title].map((title) => (
            <UnderlinePanels.Tab key={title} value={title} data-test={`${title.toLowerCase()}-tab`}>{title}</UnderlinePanels.Tab>
          ))}
          <UnderlinePanels.Panel value={dict.upload.title}>
            <div className="op-blocknote-file-content">
              <FileInput accept={types?.length ? types.join(',') : '*/*'} placeholder={placeholder}
                onChange={(file) => { void upload(file); }} />
              {uploadState === 'failed' && <div role="alert" className="bn-error-text">{dict.upload.upload_error}</div>}
            </div>
          </UnderlinePanels.Panel>
          <UnderlinePanels.Panel value={dict.embed.title}>{embed}</UnderlinePanels.Panel>
        </UnderlinePanels>
      </div>
      {loading && <div className="op-blocknote-file-progress"><Spinner srText={window.I18n.t('js.label_loading')} /></div>}
    </div>
  );
}

function FileInput({ accept, placeholder, onChange }:Pick<Panel['FileInput'], 'accept' | 'placeholder' | 'onChange'>) {
  const input = useRef<HTMLInputElement>(null);
  return (
    <>
      <Button block onClick={() => input.current?.click()}>{placeholder}</Button>
      <input ref={input} hidden type="file" accept={accept} aria-label={placeholder} data-test="upload-input"
        onChange={({ currentTarget }) => {
          const file = currentTarget.files?.item(0) ?? null;
          currentTarget.value = '';
          onChange(file);
        }} />
    </>
  );
}

// Primer TextInput maps required to aria-required. Native form validation also needs the input property (SE-661).
function requireUrl(input:HTMLInputElement | null) {
  if (input) input.required = true;
}

function EmbedInput({ placeholder, value, onChange, onKeyDown }:Panel['TextInput']) {
  return (
    <FormControl required>
      <FormControl.Label>{window.I18n.t('js.blocknote.link_url')}</FormControl.Label>
      <TextInput ref={requireUrl} block inputMode="url" autoComplete="url" data-test="embed-input"
        placeholder={placeholder} value={value} onChange={onChange} onKeyDown={onKeyDown} />
    </FormControl>
  );
}

function EmbedForm({ children, onSubmit, submitButton }:ComponentProps['Generic']['Form']['Root']) {
  return (
    <form className="op-blocknote-embed-form" onSubmit={(event) => {
      event.preventDefault();
      onSubmit?.();
    }}>
      {children}
      {submitButton !== 'none' && submitButton}
    </form>
  );
}

function PanelButton({ children, label, ...props }:Panel['Button']) {
  return <Button {...props} aria-label={label} variant="primary">{children}</Button>;
}

function TabPanel({ children }:Panel['TabPanel']) {
  return <div className="op-blocknote-file-content">{children}</div>;
}

export const primerPanel = {
  FileInput, TextInput: EmbedInput, Button: PanelButton, TabPanel,
  Root: ({ tabs, openTab, setOpenTab, loading }:Panel['Root']) => (
    <div aria-busy={loading} inert={loading}>
      <UnderlinePanels aria-label={window.I18n.t('js.blocknote.file_source')} value={openTab} onChange={({ value }) => setOpenTab(value)}>
        {tabs.map(({ name }) => <UnderlinePanels.Tab key={name} value={name}>{name}</UnderlinePanels.Tab>)}
        {tabs.map(({ name, tabPanel }) => <UnderlinePanels.Panel key={name} value={name}>{tabPanel}</UnderlinePanels.Panel>)}
      </UnderlinePanels>
    </div>
  ),
};

export function PrimerFilePanel() {
  const components = useComponentsContext()!;
  const value = useMemo(() => ({
    ...components,
    Generic: { ...components.Generic, Form: { ...components.Generic.Form, Root: EmbedForm } },
  }), [components]);
  return <ComponentsContext.Provider value={value}><FilePanelController filePanel={MediaPanel} /></ComponentsContext.Provider>;
}

export function PrimerReplaceButton() {
  const editor = useBlockNoteEditor();
  const panel = useExtension(FilePanelExtension);
  const labels = useDictionary().formatting_toolbar.file_replace.tooltip;
  const target = useEditorState({
    editor,
    selector: () => {
      const blocks = editor.getSelection()?.blocks ?? [editor.getTextCursorPosition().block];
      const [block] = blocks;
      if (!editor.isEditable || blocks.length !== 1 || !('url' in block.props)) return undefined;
      return { id: block.id, type: block.type };
    },
  });
  if (!target) return null;
  return <IconButton icon={ArrowSwitchIcon} aria-label={labels[target.type] ?? labels.file} size="medium" variant="invisible"
    onMouseDown={preventFocusOnTap} onClick={() => panel.showMenu(target.id)} />;
}
