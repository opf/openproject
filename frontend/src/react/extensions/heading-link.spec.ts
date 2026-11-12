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

import { BlockNoteEditor, PartialBlock } from '@blocknote/core';
import { getByRole, queryByRole } from '@testing-library/dom';
import { vi } from 'vitest';
import { HeadingLinkExtension } from './heading-link';

const paragraphs = (count:number):PartialBlock[] =>
  Array.from({ length: count }, (_, index) => ({ type: 'paragraph', content: `Paragraph ${index + 1}` }));

const headingFarDown:PartialBlock[] = [
  ...paragraphs(60),
  { id: 'target', type: 'heading', props: { level: 2 }, content: 'Target heading' },
  ...paragraphs(60),
];

const singleHeading:PartialBlock[] = [{ id: 'target', type: 'heading', content: 'Intro' }];

const cleanups:(() => void)[] = [];

function mountEditor(initialContent?:PartialBlock[], parent:Node = document.body) {
  const container = document.createElement('div');
  parent.appendChild(container);
  const editor = BlockNoteEditor.create({ initialContent, extensions: [HeadingLinkExtension] });
  editor.mount(container);
  cleanups.push(() => {
    editor.unmount();
    container.remove();
  });

  return { editor, container };
}

function mountEditorInShadowRoot(initialContent:PartialBlock[]) {
  const host = document.createElement('div');
  document.body.appendChild(host);
  cleanups.push(() => host.remove());
  const shadowRoot = host.attachShadow({ mode: 'open' });

  return { ...mountEditor(initialContent, shadowRoot), shadowRoot };
}

function setHash(hash:string) {
  window.history.replaceState(null, '', `${window.location.pathname}${window.location.search}${hash}`);
}

// The scroll position snaps to device pixels, so on a high-density screen a heading at a
// fractional offset can come to rest a fraction of a pixel above the top.
const SUBPIXEL_TOLERANCE = 1;

function isInViewport(element:Element) {
  const { top, bottom, height } = element.getBoundingClientRect();
  return height > 0 && top > -SUBPIXEL_TOLERANCE && bottom < window.innerHeight + SUBPIXEL_TOLERANCE;
}

const headingElement = (root:ParentNode = document) =>
  root.querySelector('[data-id="target"] [data-content-type="heading"]');

const linkButtons = (root:ParentNode = document) =>
  root.querySelectorAll<HTMLButtonElement>('.op-heading-link');

async function linkButton(root:ParentNode = document) {
  await expect.poll(() => linkButtons(root).length).toBe(1);
  return linkButtons(root)[0];
}

function headingIsInView(root:ParentNode = document) {
  const heading = headingElement(root);
  return !!heading && isInViewport(heading);
}

// Chrome's scroll anchoring would hide the shift.
function growBlocksAbove() {
  const style = document.createElement('style');
  style.textContent = `
    html { overflow-anchor: none; }
    [data-node-type="blockContainer"]:has([data-content-type="paragraph"]) { padding-top: 60px; }
  `;
  document.head.append(style);
  cleanups.push(() => style.remove());
}

function takeOver() {
  window.dispatchEvent(new PointerEvent('pointerdown'));
}

function click(element:Element) {
  element.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
  element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
}

// Desktop Firefox and WebKit construct neither Touch nor TouchEvent.
function touchEvent(type:string, point:{ clientX:number, clientY:number }) {
  const event = new Event(type, { bubbles: true, cancelable: true });
  Object.defineProperty(event, 'changedTouches', { value: [point] });
  return event;
}

function tap(element:Element) {
  const { left, top, width, height } = element.getBoundingClientRect();
  const point = { clientX: left + width / 2, clientY: top + height / 2 };
  element.dispatchEvent(touchEvent('touchstart', point));
  element.dispatchEvent(touchEvent('touchend', point));
}

function mockClipboard(write:() => Promise<void> = () => Promise.resolve()) {
  return vi.spyOn(navigator.clipboard, 'writeText').mockImplementation(write);
}

describe('HeadingLinkExtension', () => {
  afterEach(() => {
    cleanups.splice(0).reverse().forEach((cleanup) => cleanup());
    setHash('');
    window.scrollTo(0, 0);
    vi.restoreAllMocks();
  });

  it('adds a link button to every heading and to nothing else', async () => {
    mountEditor([
      { type: 'heading', props: { level: 1 }, content: 'One' },
      { type: 'paragraph', content: 'Text' },
      { type: 'heading', props: { level: 2 }, content: 'Two' },
      { type: 'heading', props: { level: 3 }, content: 'Three' },
      { type: 'heading', content: '' },
    ]);

    await expect.poll(() => linkButtons().length).toBe(3);
    linkButtons().forEach((button) => expect(button.closest('[data-content-type="heading"]')).not.toBeNull());
  });

  it('keeps the buttons in step with edits to headings and around them', async () => {
    const { editor } = mountEditor([
      { id: 'empty', type: 'heading', content: '' },
      { id: 'paragraph', type: 'paragraph', content: 'Text' },
      { id: 'heading', type: 'heading', content: 'Heading' },
    ]);
    const buttonOwners = () => Array.from(linkButtons(), (button) => button.closest('[data-id]')?.getAttribute('data-id'));
    await expect.poll(buttonOwners).toEqual(['heading']);

    editor.setTextCursorPosition('paragraph', 'end');
    editor.insertInlineContent(' more');
    expect(buttonOwners()).toEqual(['heading']);

    editor.setTextCursorPosition('empty', 'end');
    editor.insertInlineContent('Named');
    expect(buttonOwners()).toEqual(['empty', 'heading']);

    editor.updateBlock('paragraph', { type: 'heading' });
    expect(buttonOwners()).toEqual(['empty', 'paragraph', 'heading']);

    editor.updateBlock('heading', { type: 'paragraph' });
    editor.removeBlocks(['empty']);
    expect(buttonOwners()).toEqual(['paragraph']);
  });

  it('keeps the button away from assistive technology, so the heading keeps its own name', async () => {
    const { container } = mountEditor([{ type: 'heading', content: 'Intro' }]);
    await linkButton();

    expect(queryByRole(container, 'button')).toBeNull();
    expect(getByRole(container, 'heading', { name: 'Intro' })).toBeInTheDocument();
  });

  it('copies a link to the heading without changing the address', async () => {
    const writeText = mockClipboard();
    mountEditor(singleHeading);
    const button = await linkButton();

    click(button);

    expect(writeText).toHaveBeenCalledExactlyOnceWith(
      `${window.location.origin}${window.location.pathname}${window.location.search}#heading-target`,
    );
    await expect.poll(() => button.dataset.state).toBe('copied');
    expect(window.location.hash).toBe('');
  });

  it('says so when the clipboard refuses the link', async () => {
    mockClipboard(() => Promise.reject(new Error('denied')));
    mountEditor(singleHeading);
    const button = await linkButton();

    click(button);

    await expect.poll(() => button.dataset.state).toBe('failed');
  });

  it('copies on the first tap, once', async () => {
    const writeText = mockClipboard();
    mountEditor(singleHeading);
    const button = await linkButton();

    tap(button);
    button.click();

    expect(writeText).toHaveBeenCalledOnce();
  });

  it('leaves the caret where it was', async () => {
    mockClipboard();
    const { editor } = mountEditor([
      { type: 'heading', content: 'Intro' },
      { id: 'body', type: 'paragraph', content: 'Body' },
    ]);
    editor.setTextCursorPosition('body', 'end');
    const button = await linkButton();

    const mousedown = new MouseEvent('mousedown', { bubbles: true, cancelable: true });
    button.dispatchEvent(mousedown);
    button.click();

    expect(mousedown.defaultPrevented).toBe(true);
    expect(editor.getTextCursorPosition().block.id).toBe('body');
  });

  it('copies from a read-only document', async () => {
    const writeText = mockClipboard();
    const { editor } = mountEditor(singleHeading);
    editor.isEditable = false;

    click(await linkButton());

    expect(writeText).toHaveBeenCalledOnce();
  });

  it('scrolls to the heading the address points to, inside a shadow root', async () => {
    setHash('#heading-target');
    const { shadowRoot } = mountEditorInShadowRoot(headingFarDown);

    await expect.poll(() => headingIsInView(shadowRoot)).toBe(true);
    expect(window.location.hash).toBe('#heading-target');
  });

  it('scrolls once the heading arrives after the editor', async () => {
    setHash('#heading-target');
    const { editor } = mountEditor();

    editor.replaceBlocks(editor.document, headingFarDown);

    await expect.poll(() => headingIsInView()).toBe(true);
  });

  it('opens the collapsed toggles around the heading it scrolls to', async () => {
    setHash('#heading-target');
    const { container } = mountEditor([
      {
        type: 'toggleListItem',
        content: 'Outer toggle',
        children: [{
          type: 'toggleListItem',
          content: 'Inner toggle',
          children: [{ id: 'target', type: 'heading', props: { level: 2 }, content: 'Target heading' }],
        }],
      },
    ]);

    await expect.poll(() => Array.from(container.querySelectorAll('.bn-toggle-wrapper'), (toggle) => toggle.getAttribute('data-show-children')))
      .toEqual(['true', 'true']);
  });

  it('keeps the heading in view while the content above it grows', async () => {
    setHash('#heading-target');
    mountEditor(headingFarDown);
    await expect.poll(() => headingIsInView()).toBe(true);

    growBlocksAbove();

    await expect.poll(() => headingIsInView()).toBe(true);
  });

  it('stops following the heading once the user takes over', async () => {
    setHash('#heading-target');
    mountEditor(headingFarDown);
    await expect.poll(() => headingIsInView()).toBe(true);

    takeOver();
    growBlocksAbove();

    await expect.poll(() => isInViewport(headingElement()!)).toBe(false);
  });

  it('does not jump to a heading that appears after the user took over', async () => {
    setHash('#heading-target');
    const { editor } = mountEditor();

    takeOver();
    editor.replaceBlocks(editor.document, headingFarDown);

    await expect.poll(() => headingElement()).not.toBeNull();
    expect(window.scrollY).toBe(0);
  });

  it('scrolls when the address changes to another heading', async () => {
    mountEditor(headingFarDown);
    await expect.poll(() => headingElement()).not.toBeNull();
    expect(isInViewport(headingElement()!)).toBe(false);

    window.location.hash = '#heading-target';

    await expect.poll(() => headingIsInView()).toBe(true);
  });

  it('ignores an address that names no heading', async () => {
    setHash('#heading-missing');
    mountEditor(headingFarDown);

    await expect.poll(() => headingElement()).not.toBeNull();
    expect(window.scrollY).toBe(0);
  });

  it('opens the document when the address holds a malformed anchor', async () => {
    setHash('#heading-50%');
    mountEditor(singleHeading);

    expect(await linkButton()).toBeDefined();
  });
});
