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

import browser from 'webextension-polyfill';
import { llmClient } from '../clients/llm';
import { McpClient, OpenProjectClient } from '../clients/openproject';
import { connectToPage, type PageLink, tokenTransport, type Transport } from '../clients/transport';
import { systemPrompt } from '../core/outputRules';
import { DEFAULT_BASE_URLS, DEFAULT_MODELS, DEFAULT_SKILLS } from '../shared/defaults';
import { isTrustedOrigin, originPattern } from '../shared/hosts';
import { deleteAllChats, loadSettings, newId, saveSettings } from '../shared/storage';
import { asText } from '../shared/text';
import type { LlmProvider, ProposalScope, Settings, Skill } from '../shared/types';
import { h, hashParams } from './dom';
import { parseSkillImport } from './skillImport';

const params = hashParams();
const channel = params.get('channel');
const hashOrigin = params.get('origin');
const hashBasePath = params.get('base') ?? '';
const locale = (params.get('lang') ?? navigator.language).split('-')[0] ?? 'en';
const pageLink:Promise<PageLink | null> = channel && hashOrigin
  ? connectToPage(channel, hashOrigin).catch(() => null)
  : Promise.resolve(null);
// The origin of the My account page that holds this frame, once it is known to be a granted
// host. Until then, and on the options page, the settings use only the stored instance.
let pageOrigin:string | null = null;

const app = document.getElementById('app')!;
let settings:Settings;
let link:PageLink | null = null;
let editing:Skill | null = null;
const status = h('span', { class: 'small' });

const SCOPES:{ value:ProposalScope; label:string; caption:string }[] = [
  { value: 'changes', label: 'Changes', caption: 'Proposes changes to attributes and comments.' },
  { value: 'comment_only', label: 'Comment only', caption: 'Proposes comments only.' },
  { value: 'read_only', label: 'Read-only', caption: 'Proposes nothing.' },
];

function field(label:string, control:HTMLElement, caption?:string):HTMLElement {
  return h('label', { class: 'field' }, h('span', {}, label), h('span', { class: 'stack' }, control, caption ? h('span', { class: 'small muted' }, caption) : null));
}

function input(type:string, value:string, onInput:(value:string) => void, attributes:Record<string, string> = {}):HTMLInputElement {
  const element = h('input', { type, value, ...attributes });
  element.addEventListener('input', () => onInput(element.value));
  return element;
}

function textarea(value:string, onInput:(value:string) => void, rows = 4):HTMLTextAreaElement {
  const element = h('textarea', { rows: String(rows) });
  element.value = value;
  element.addEventListener('input', () => onInput(element.value));
  return element;
}

function select<T extends string>(value:T, options:{ value:T; label:string }[], onChange:(value:T) => void):HTMLSelectElement {
  const element = h('select', {}, ...options.map((option) => h('option', { value: option.value, selected: option.value === value }, option.label)));
  element.addEventListener('change', () => onChange(element.value as T));
  return element;
}

function transport():Transport | null {
  const instance = settings.instanceUrl !== '' ? settings.instanceUrl : pageOrigin ?? '';
  if (settings.authMode === 'token' && settings.apiToken && instance) return tokenTransport(instance, settings.apiToken);
  return link?.transport ?? null;
}

async function testConnection(target:HTMLElement):Promise<void> {
  const current = transport();
  if (!current) {
    target.textContent = 'Open these settings from My account → AI Assistance to use the browser session, or enter an API token.';
    return;
  }
  target.textContent = 'Checking…';
  try {
    const op = new OpenProjectClient(current);
    const me = await op.get('/api/v3/users/me');
    let tools = 'MCP tools: not checked.';
    try {
      tools = `${(await new McpClient(op).readOnlyTools()).definitions.length} read-only MCP tools available.`;
    } catch (error) {
      tools = `MCP tools: ${error instanceof Error ? error.message : String(error)} Ask an administrator to enable the MCP server.`;
    }
    target.className = 'small success';
    target.textContent = `Connected as ${asText(me.name, 'unknown')}. ${tools}`;
  } catch (error) {
    target.className = 'small error';
    target.textContent = `The connection failed: ${error instanceof Error ? error.message : String(error)}`;
  }
}

async function testModel(target:HTMLElement):Promise<void> {
  target.className = 'small';
  target.textContent = 'Asking the model…';
  try {
    const turn = await llmClient(settings).complete({ system: 'Reply with the single word OK.', messages: [{ role: 'user', content: 'Test' }], tools: [] });
    target.className = 'small success';
    target.textContent = `The model answered: ${turn.text.slice(0, 80)}`;
  } catch (error) {
    target.className = 'small error';
    target.textContent = error instanceof Error ? error.message : String(error);
  }
}

function connectionSection():HTMLElement {
  const result = h('span', { class: 'small' });
  const instance = settings.instanceUrl;
  return h('section', {},
    h('h2', {}, 'Connection'),
    field('OpenProject', pageOrigin
      ? h('span', {}, instance)
      : input('url', settings.instanceUrl, (value) => { settings.instanceUrl = value; }, { placeholder: 'https://openproject.example.com' })),
    field('Sign-in', select(settings.authMode, [
      { value: 'session', label: 'Browser session' },
      { value: 'token', label: 'API token' },
    ], (value) => { settings.authMode = value; render(); }),
    settings.authMode === 'session'
      ? 'Uses your sign-in in this browser. Works only on the OpenProject page.'
      : 'Create the token at My account → Access tokens → API.'),
    settings.authMode === 'token'
      ? field('API token', input('password', settings.apiToken, (value) => { settings.apiToken = value; }, { autocomplete: 'off' }))
      : null,
    h('div', { class: 'row' }, h('button', { onclick: () => void testConnection(result) }, 'Test the connection'), result));
}

function modelSection():HTMLElement {
  const result = h('span', { class: 'small' });
  return h('section', {},
    h('h2', {}, 'Model'),
    field('Provider', select<LlmProvider>(settings.provider, [
      { value: 'anthropic', label: 'Anthropic' },
      { value: 'openai', label: 'OpenAI or compatible' },
    ], (value) => {
      settings.provider = value;
      settings.model = DEFAULT_MODELS[value];
      render();
    })),
    field('API key', input('password', settings.llmKey, (value) => { settings.llmKey = value; }, { autocomplete: 'off' }),
      'Stays in this browser. The extension sends it only to the provider.'),
    field('Model', input('text', settings.model, (value) => { settings.model = value; })),
    field('Server URL', input('url', settings.llmBaseUrl, (value) => { settings.llmBaseUrl = value; }, { placeholder: DEFAULT_BASE_URLS[settings.provider] }),
      'Empty uses the provider default.'),
    h('div', { class: 'row' }, h('button', { onclick: () => void testModel(result) }, 'Test the model'), result));
}

function instructionsSection():HTMLElement {
  return h('section', {},
    h('h2', {}, 'Assistant prompt'),
    field('Prompt', textarea(settings.instructions, (value) => { settings.instructions = value; }),
      'Shared by every skill, before the skill prompt: for example who the assistant helps and what their work is about.'));
}

function skillEditor(skill:Skill):HTMLElement {
  const preview = h('pre', {});
  const updatePreview = ():void => {
    preview.textContent = systemPrompt(settings.instructions, skill, { locale, tools: skill.useTools });
  };
  const checkbox = (checked:boolean, onChange:(value:boolean) => void, label:string, caption:string):HTMLElement => {
    const element = h('input', { type: 'checkbox', checked });
    element.addEventListener('change', () => { onChange(element.checked); updatePreview(); });
    return h('label', { class: 'stack' }, h('span', { class: 'row' }, element, h('strong', {}, label)), h('span', { class: 'small muted' }, caption));
  };
  updatePreview();

  return h('div', { class: 'editor' },
    field('Label', input('text', skill.label, (value) => { skill.label = value; })),
    field('Icon', input('text', skill.icon, (value) => { skill.icon = value; }, { maxlength: '4' }), 'One character or emoji.'),
    field('Description', input('text', skill.description, (value) => { skill.description = value; }), 'Shown under the label in the menu.'),
    field('Skill prompt', textarea(skill.prompt, (value) => { skill.prompt = value; updatePreview(); }, 10),
      'What the model does in this skill. Without it, the skill is not offered.'),
    field('Proposals', select(skill.scope, SCOPES, (value) => { skill.scope = value; updatePreview(); }),
      SCOPES.map((scope) => `${scope.label}: ${scope.caption}`).join(' ')),
    checkbox(skill.answersAtOnce, (value) => { skill.answersAtOnce = value; }, 'Answer at once when opened',
      'Opening the skill starts a new chat, and the skill answers its prompt at once. Off opens an empty chat for the user\'s own questions.'),
    checkbox(skill.useTools, (value) => { skill.useTools = value; }, 'Use OpenProject MCP tools',
      'The AI can search OpenProject for more data than the work package. It sees only what you can see, and the tools cannot change anything.'),
    h('details', {}, h('summary', {}, 'Show the full system prompt'), preview),
    h('div', { class: 'row' }, h('button', { onclick: () => { editing = null; render(); } }, 'Done')));
}

function skillsSection():HTMLElement {
  const fileInput = h('input', { type: 'file', accept: 'application/json', hidden: true });
  fileInput.addEventListener('change', () => {
    const file = fileInput.files?.[0];
    if (!file) return;
    void file.text().then((text) => {
      try {
        const imported = parseSkillImport(text);
        settings.skills = imported.skills;
        if (imported.instructions !== undefined) settings.instructions = imported.instructions;
        status.className = 'small success';
        status.textContent = `Imported ${imported.skills.length} skills. Save to keep them.`;
      } catch (error) {
        status.className = 'small error';
        status.textContent = error instanceof Error ? error.message : String(error);
      }
      render();
    });
  });

  const exportSkills = ():void => {
    const blob = new Blob([JSON.stringify({ instructions: settings.instructions, skills: settings.skills }, null, 2)], { type: 'application/json' });
    const anchor = h('a', { href: URL.createObjectURL(blob), download: 'op-ai-assistance-skills.json' });
    anchor.click();
    URL.revokeObjectURL(anchor.href);
  };

  return h('section', {},
    h('div', { class: 'row' },
      h('h2', {}, 'Skills'),
      h('span', { class: 'spacer' }),
      h('button', {
        onclick: () => {
          editing = { id: newId(), label: 'New skill', description: '', icon: '✦', prompt: '', scope: 'read_only', answersAtOnce: false, useTools: true };
          settings.skills.push(editing);
          render();
        },
      }, '+ Skill'),
      h('button', { onclick: () => fileInput.click() }, 'Import'),
      h('button', { onclick: exportSkills }, 'Export'),
      h('button', { onclick: () => { settings.skills = structuredClone(DEFAULT_SKILLS); editing = null; render(); } }, 'Reset'),
      fileInput),
    h('div', {}, ...settings.skills.map((skill, index) => editing === skill
      ? skillEditor(skill)
      : h('div', { class: 'skill-row' },
        h('span', {}, skill.icon || '✦'),
        h('strong', {}, skill.label),
        h('span', { class: 'small muted' }, SCOPES.find((scope) => scope.value === skill.scope)?.label ?? ''),
        h('span', { class: 'small muted' }, skill.answersAtOnce ? 'Answers at once' : 'Opens an empty chat'),
        skill.prompt.trim() ? null : h('span', { class: 'small error' }, 'No prompt: not offered'),
        h('span', { class: 'spacer' }),
        h('button', { onclick: () => { editing = skill; render(); } }, 'Edit'),
        h('button', {
          onclick: () => {
            settings.skills.splice(index + 1, 0, { ...structuredClone(skill), id: newId(), label: `${skill.label} (copy)` });
            render();
          },
        }, 'Copy'),
        h('button', { class: 'danger', onclick: () => { settings.skills.splice(index, 1); render(); } }, 'Delete')))));
}

function privacySection():HTMLElement {
  const result = h('span', { class: 'small' });
  return h('section', {},
    h('h2', {}, 'Privacy'),
    h('p', {}, 'The API key and the chats stay in this browser. The model sees the work package and what the tools find, which is only what you can see in OpenProject.'),
    h('div', { class: 'row' },
      h('button', {
        class: 'danger',
        onclick: () => void deleteAllChats().then((count) => { result.textContent = `Deleted the chats of ${count} work packages.`; }),
      }, 'Delete all chats'),
      result));
}

// permissions.request must run in the click handler, while the user gesture is active. The
// settings are written first, so that the background knows the LLM server when the grant
// arrives. A provider with CORS (Anthropic) also works without the permission.
function save():void {
  const base = settings.llmBaseUrl.trim() || DEFAULT_BASE_URLS[settings.provider];
  const saved = saveSettings(settings);
  void browser.permissions.request({ origins: [originPattern(base)] })
    .catch(() => false)
    .then(async () => {
      await saved;
      status.className = 'small success';
      status.textContent = 'Saved.';
    })
    .catch((error:unknown) => {
      status.className = 'small error';
      status.textContent = error instanceof Error ? error.message : String(error);
    });
}

function render():void {
  app.replaceChildren(
    h('h1', {}, 'AI Assistance'),
    h('p', { class: 'muted' }, 'AI Assistance adds skills to your work packages. Each skill runs with your OpenProject permissions and your own LLM key, and changes nothing until you apply a proposal.'),
    connectionSection(),
    modelSection(),
    instructionsSection(),
    skillsSection(),
    privacySection(),
    h('div', { class: 'row sticky' }, h('button', { class: 'primary', onclick: save }, 'Save'), status));
}

async function main():Promise<void> {
  const [stored, { origins = [] }] = await Promise.all([loadSettings(), browser.permissions.getAll()]);
  settings = stored;
  if (isTrustedOrigin(hashOrigin, origins, settings.llmBaseUrl)) {
    pageOrigin = hashOrigin;
    link = await pageLink;
    settings.instanceUrl = `${hashOrigin}${hashBasePath}`;
  }
  render();
}

void main();
