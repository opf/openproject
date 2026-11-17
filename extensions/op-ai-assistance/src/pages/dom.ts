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

type Child = Node | string | null | undefined | false;
type Attributes = Record<string, string | boolean | ((event:Event) => void) | undefined>;

export function h<K extends keyof HTMLElementTagNameMap>(tag:K, attributes:Attributes = {}, ...children:Child[]):HTMLElementTagNameMap[K] {
  const element = document.createElement(tag);
  for (const [name, value] of Object.entries(attributes)) {
    if (value === undefined || value === false) continue;
    if (typeof value === 'function') element.addEventListener(name.replace(/^on/, '').toLowerCase(), value);
    else if (value === true) element.setAttribute(name, '');
    else element.setAttribute(name, value);
  }
  element.append(...children.filter((child):child is Node | string => child !== null && child !== undefined && child !== false));
  return element;
}

function inline(text:string):Node[] {
  const nodes:Node[] = [];
  const pattern = /(\*\*[^*]+\*\*|`[^`]+`)/g;
  let last = 0;
  for (const match of text.matchAll(pattern)) {
    if (match.index > last) nodes.push(document.createTextNode(text.slice(last, match.index)));
    const token = match[0];
    nodes.push(token.startsWith('**') ? h('strong', {}, token.slice(2, -2)) : h('code', {}, token.slice(1, -1)));
    last = match.index + token.length;
  }
  if (last < text.length) nodes.push(document.createTextNode(text.slice(last)));
  return nodes;
}

// Model answers are Markdown from an untrusted source: this renders paragraphs, lists,
// headings, bold and code as DOM nodes, and everything else as text. No HTML, no links, no
// images, so an answer cannot load a URL.
export function markdown(text:string):HTMLElement {
  const root = h('div', { class: 'markdown' });
  let list:HTMLElement | null = null;
  for (const block of text.split(/\n{2,}/)) {
    for (const line of block.split('\n')) {
      const item = /^\s*(?:[-*]|\d+\.)\s+(.*)$/.exec(line);
      if (item) {
        list ??= root.appendChild(h(/^\s*\d/.test(line) ? 'ol' : 'ul'));
        list.append(h('li', {}, ...inline(item[1] ?? '')));
        continue;
      }
      list = null;
      const heading = /^#{1,6}\s+(.*)$/.exec(line);
      if (heading) root.append(h('h4', {}, ...inline(heading[1] ?? '')));
      else if (line.trim()) root.append(h('p', {}, ...inline(line)));
    }
    list = null;
  }
  return root;
}

export function hashParams():URLSearchParams {
  return new URLSearchParams(window.location.hash.slice(1));
}
