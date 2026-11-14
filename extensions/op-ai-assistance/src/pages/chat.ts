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
import { answer } from '../clients/assistant';
import { OpenProjectClient } from '../clients/openproject';
import { connectToPage, type PageLink, tokenTransport } from '../clients/transport';
import { ApplyError, applyProposal } from '../clients/workPackages';
import { START_REQUEST } from '../shared/defaults';
import { isTrustedOrigin } from '../shared/hosts';
import { loadChats, loadSettings, newId, saveChat } from '../shared/storage';
import type { Chat, ChatMessage, Proposal, RunEvent, Settings, Skill } from '../shared/types';
import { h, hashParams, markdown } from './dom';

const params = hashParams();
const workPackageId = params.get('wp') ?? '';
const origin = params.get('origin') ?? '';
const basePath = params.get('base') ?? '';
const locale = (params.get('lang') ?? 'en').split('-')[0] ?? 'en';
// Registered before anything awaits, so the page's connection on frame load finds it.
const pageLink = connectToPage(params.get('channel') ?? '', origin);

const app = document.getElementById('app')!;

interface State {
  settings:Settings;
  link:PageLink;
  op:OpenProjectClient;
  chats:Chat[];
  chat:Chat | null;
  view:'menu' | 'history' | 'chat';
  busy:boolean;
  appliedSomething:boolean;
  error:string | null;
}

let state:State;

const skillOf = (chat:Chat):Skill | undefined => state.settings.skills.find((skill) => skill.id === chat.skillId);
const assistantName = 'AI Assistance';

function header():HTMLElement {
  return h('header', {},
    h('h1', {}, `AI Assistance · #${workPackageId}`),
    h('span', { class: 'spacer' }),
    h('button', { disabled: state.busy, onclick: () => show('menu', null) }, 'New chat'),
    h('button', { disabled: state.busy, onclick: () => show('history', null) }, 'History'),
    h('button', { 'aria-label': 'Close', onclick: () => state.link.control('close') }, '×'));
}

// One answer at a time: while it runs, the dialog does not switch chats or start a skill.
function show(view:State['view'], chat:Chat | null):void {
  if (state.busy) return;
  state.view = view;
  state.chat = chat;
  state.error = null;
  render();
}

function setupNotice():HTMLElement {
  return h('div', { class: 'notice stack' },
    h('strong', {}, 'Set up AI Assistance first'),
    h('p', {}, 'Enter your LLM provider and key in My account → AI Assistance.'),
    h('div', {}, h('button', { class: 'primary', onclick: () => state.link.control('settings') }, 'Open settings')));
}

function menuView():HTMLElement[] {
  if (!state.settings.llmKey) return [setupNotice()];
  const skills = state.settings.skills.filter((skill) => skill.prompt.trim());
  if (skills.length === 0) return [h('p', { class: 'muted' }, 'There are no skills. Add one in the settings.')];
  return skills.map((skill) => h('button', { class: 'skill', onclick: () => void startSkill(skill) },
    h('span', { class: 'icon' }, skill.icon || '✦'),
    h('span', {}, h('strong', {}, skill.label), h('span', { class: 'small muted' }, skill.description))));
}

function historyView():HTMLElement[] {
  if (state.chats.length === 0) return [h('p', { class: 'muted' }, 'You did not use AI Assistance on this work package yet.')];
  return state.chats.map((chat) => {
    const answers = chat.messages.filter((message) => message.role === 'assistant').length;
    return h('button', { class: 'skill', onclick: () => show('chat', chat) },
      h('span', { class: 'icon' }, skillOf(chat)?.icon ?? '✦'),
      h('span', {},
        h('strong', {}, skillOf(chat)?.label ?? 'Chat'),
        h('span', { class: 'small muted' }, `${new Date(chat.createdAt).toLocaleString()} · ${answers} ${answers === 1 ? 'answer' : 'answers'}`)));
  });
}

function eventLine(event:RunEvent):HTMLElement {
  const detail = (label:string, text:string):HTMLElement => h('details', {}, h('summary', {}, label), h('pre', {}, text));
  switch (event.type) {
    case 'request':
      return h('div', {}, `Asked the model ${event.model}: prompt ${event.system.length} characters, message ${event.message.length} characters, ${event.tools} tools.`, detail('Show prompt', event.system));
    case 'thought':
      return h('div', {}, 'The model explained its next tool calls.', detail('Show text', event.text));
    case 'tool_call':
      if (event.refused) return h('div', {}, `Refused the tool ${event.name}: the limit of tool calls is reached.`);
      if (event.repeated) return h('div', {}, `Called the tool ${event.name} again with the same arguments. Sent the earlier result.`);
      if (event.error) return h('div', { class: 'error' }, `The tool ${event.name} failed (${event.error}).`);
      return h('div', {}, `Called the tool ${event.name}: ${event.seconds ?? 0} s, ${event.size ?? 0} characters.`,
        detail('Show arguments', JSON.stringify(event.arguments, null, 2)), detail('Show result', event.result ?? ''));
    case 'answer':
      return h('div', {}, `The model answered in ${event.seconds} s, after ${event.toolCalls} tool calls.`, detail('Show answer', event.content));
    case 'stored':
      return h('div', {}, `Kept ${event.stored} of ${event.findings} proposals; ${event.findings - event.stored} dropped because they had no evidence or no valid change.`,
        event.dropped.length > 0 ? detail('Show dropped proposals', JSON.stringify(event.dropped, null, 2)) : null);
    case 'note':
      return h('div', {}, event.text);
    case 'failure':
      return h('div', { class: 'error' }, `The call failed (${event.error}).`);
  }
}

function proposalCard(chat:Chat, message:ChatMessage, proposal:Proposal):HTMLElement {
  const status = h('div', { class: 'small' });
  const reasons = h('select', { 'aria-label': 'Dismiss reason' },
    h('option', { value: '' }, 'Dismiss…'),
    h('option', { value: 'wrong' }, 'Dismiss: wrong'),
    h('option', { value: 'not_relevant' }, 'Dismiss: not relevant'),
    h('option', { value: 'already_known' }, 'Dismiss: already known'));
  reasons.addEventListener('change', () => {
    if (!reasons.value) return;
    proposal.state = 'dismissed';
    proposal.dismissReason = reasons.value;
    void saveChat(origin, chat).catch(() => undefined).then(render);
  });

  const apply = h('button', { class: 'primary' }, 'Apply changes');
  apply.addEventListener('click', () => {
    apply.disabled = true;
    status.textContent = '';
    applyProposal(state.op, workPackageId, proposal)
      .then(async () => {
        proposal.state = 'applied';
        state.appliedSomething = true;
        await saveChat(origin, chat).catch(() => undefined);
        render();
      })
      .catch((error:unknown) => {
        apply.disabled = false;
        status.className = 'small error';
        status.textContent = error instanceof ApplyError || error instanceof Error ? error.message : 'The changes could not be applied.';
      });
  });

  const open = proposal.state === 'open' && message.status === 'done';
  return h('div', { class: `proposal ${proposal.state}` },
    h('div', { class: 'row' },
      proposal.severity ? h('span', { class: `badge ${proposal.severity}` }, proposal.severity) : null,
      proposal.area ? h('span', { class: 'badge' }, proposal.area) : null,
      proposal.state !== 'open' ? h('span', { class: 'badge' }, proposal.state === 'applied' ? 'Applied' : 'Dismissed') : null),
    proposal.text ? markdown(proposal.text) : null,
    proposal.evidence.length > 0 ? h('ul', { class: 'evidence' }, ...proposal.evidence.map((item) => h('li', {}, item))) : null,
    ...proposal.actions.map((action) => {
      const label = action.key === 'comment' ? 'Proposed comment' : `Proposed ${action.key.replace('_', ' ')}`;
      return action.key === 'description' || action.key === 'comment'
        ? h('details', { class: 'change' }, h('summary', {}, h('span', { class: 'key' }, label)), markdown(action.label))
        : h('div', { class: 'change' }, h('span', { class: 'key' }, `${label}: `), action.label);
    }),
    open && proposal.actions.length > 0 ? h('div', { class: 'row' }, apply, reasons) : null,
    status);
}

function messageView(chat:Chat, message:ChatMessage):HTMLElement {
  if (message.role === 'start') return h('div', { class: 'message start' }, `Started ${skillOf(chat)?.label ?? 'the skill'}`);
  if (message.role === 'user') return h('div', { class: 'message user' }, message.content);

  return h('div', { class: 'message assistant' },
    message.status === 'failed'
      ? h('p', { class: 'error' }, 'The answer failed. Open Details for more, or ask again.')
      : markdown(message.content),
    ...message.proposals.map((proposal) => proposalCard(chat, message, proposal)),
    message.events.length > 0
      ? h('details', {}, h('summary', { class: 'small muted' }, 'Details'), h('div', { class: 'events' }, ...message.events.map(eventLine)))
      : null);
}

function chatView(chat:Chat):HTMLElement[] {
  const skill = skillOf(chat);
  return [
    h('h2', {}, skill?.label ?? 'Chat'),
    ...chat.messages.map((message) => messageView(chat, message)),
    state.busy ? h('div', { class: 'row muted' }, h('span', { class: 'spinner' }), `${assistantName} is working on #${workPackageId}…`) : null,
    state.appliedSomething
      ? h('div', { class: 'notice row' }, 'The changes were applied.', h('span', { class: 'spacer' }),
        h('button', { onclick: () => state.link.control('reload') }, 'Reload the page'))
      : null,
  ].filter((node):node is HTMLElement => node !== null);
}

function composer(chat:Chat):HTMLElement {
  const skill = skillOf(chat);
  const input = h('textarea', { placeholder: `Ask something about #${workPackageId}…`, 'aria-label': 'Question' });
  const send = ():void => {
    const text = input.value.trim();
    if (!text || state.busy) return;
    void ask(chat, { role: 'user', content: text });
  };
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) send();
  });
  return h('footer', {},
    state.error ? h('div', { class: 'small error' }, state.error) : null,
    input,
    h('div', { class: 'row' },
      skill?.answersAtOnce ? h('button', { disabled: state.busy, onclick: () => void ask(chat, { role: 'start', content: START_REQUEST }) }, 'Run again') : null,
      h('span', { class: 'spacer' }),
      h('span', { class: 'small muted' }, '⌘/Ctrl + Enter'),
      h('button', { class: 'primary', disabled: state.busy, onclick: send }, 'Send')));
}

function render():void {
  const body = h('div', { class: 'body' });
  if (state.view === 'menu') body.append(...menuView());
  if (state.view === 'history') body.append(...historyView());
  if (state.view === 'chat' && state.chat) body.append(...chatView(state.chat));

  app.replaceChildren(header(), body, ...(state.view === 'chat' && state.chat ? [composer(state.chat)] : []));
  body.scrollTop = body.scrollHeight;
}

async function ask(chat:Chat, question:Pick<ChatMessage, 'role' | 'content'>):Promise<void> {
  if (state.busy) return;
  const skill = skillOf(chat);
  if (!skill) {
    state.error = 'This skill no longer exists. You can read the chat, but not continue it.';
    render();
    return;
  }

  chat.messages.push({ id: newId(), createdAt: new Date().toISOString(), status: 'done', proposals: [], events: [], ...question });
  state.busy = true;
  state.chat = chat;
  state.view = 'chat';
  render();

  try {
    chat.messages.push(await answer({ settings: state.settings, skill, chat, op: state.op, locale }));
    await saveChat(origin, chat);
    state.chats = await loadChats(origin, workPackageId);
  } catch (error) {
    state.error = `The chat could not be saved: ${error instanceof Error ? error.message : String(error)}`;
  } finally {
    state.busy = false;
    render();
  }
}

async function startSkill(skill:Skill):Promise<void> {
  if (state.busy) return;
  const chat:Chat = { id: newId(), skillId: skill.id, workPackageId, createdAt: new Date().toISOString(), messages: [] };
  if (skill.answersAtOnce) {
    await ask(chat, { role: 'start', content: START_REQUEST });
  } else {
    show('chat', chat);
  }
}

async function main():Promise<void> {
  app.replaceChildren(h('div', { class: 'body row muted' }, h('span', { class: 'spinner' }), 'Loading…'));
  try {
    const [settings, { origins = [] }] = await Promise.all([loadSettings(), browser.permissions.getAll()]);
    if (!isTrustedOrigin(origin, origins, settings.llmBaseUrl)) {
      throw new Error('AI Assistance is not enabled for this page.');
    }
    const [link, chats] = await Promise.all([pageLink, loadChats(origin, workPackageId)]);
    const transport = settings.authMode === 'token' && settings.apiToken
      ? tokenTransport(`${origin}${basePath}`, settings.apiToken)
      : link.transport;
    state = {
      settings,
      link,
      op: new OpenProjectClient(transport),
      chats,
      chat: null,
      view: 'menu',
      busy: false,
      appliedSomething: false,
      error: null,
    };
    render();
  } catch (error) {
    app.replaceChildren(h('div', { class: 'body' }, h('p', { class: 'error' }, error instanceof Error ? error.message : String(error))));
  }
}

// Key events inside this frame do not reach the page, so the frame handles Escape itself.
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') void pageLink.then((link) => link.control('close'), () => undefined);
});

void main();
