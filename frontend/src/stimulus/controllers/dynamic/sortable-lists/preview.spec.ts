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

import { renderDragPreview, sanitizePreview } from './preview';

describe('sortable lists drag preview', () => {
  function previewTarget():HTMLElement {
    const article = document.createElement('article');
    article.setAttribute('data-controller', 'backlogs--work-package');
    article.setAttribute('data-action', 'click->backlogs--work-package#onClick');
    article.setAttribute('data-sortable-lists--item-target', 'preview');
    article.setAttribute('data-dragging', 'source');
    article.setAttribute('data-drop-position', 'top');
    article.setAttribute('data-drop-position-owner', '123');
    article.setAttribute('data-selected', '');
    article.setAttribute('aria-current', 'true');
    article.setAttribute('aria-roledescription', 'draggable');

    const fragment = document.createElement('include-fragment');
    fragment.setAttribute('src', '/lazy');
    article.appendChild(fragment);

    const child = document.createElement('div');
    child.setAttribute('data-controller', 'nested');
    child.setAttribute('data-nested--thing-target', 'child');
    article.appendChild(child);

    return article;
  }

  describe('sanitizePreview', () => {
    it('strips behaviour and interaction-state attributes from the clone', () => {
      const element = previewTarget();

      sanitizePreview(element);

      expect(element.hasAttribute('data-controller')).toBe(false);
      expect(element.hasAttribute('data-action')).toBe(false);
      expect(element.hasAttribute('data-sortable-lists--item-target')).toBe(false);
      expect(element.hasAttribute('data-dragging')).toBe(false);
      expect(element.hasAttribute('data-drop-position')).toBe(false);
      expect(element.hasAttribute('data-drop-position-owner')).toBe(false);
      expect(element.hasAttribute('data-selected')).toBe(false);
      expect(element.hasAttribute('aria-current')).toBe(false);
      expect(element.hasAttribute('aria-roledescription')).toBe(false);
    });

    it('strips dynamic target attributes from descendants', () => {
      const element = previewTarget();

      sanitizePreview(element);

      expect(element.querySelector('[data-controller]')).toBeNull();
      expect(element.querySelector('[data-nested--thing-target]')).toBeNull();
    });

    it('removes include-fragment elements so no lazy fetch fires from the clone', () => {
      const element = previewTarget();

      sanitizePreview(element);

      expect(element.querySelector('include-fragment')).toBeNull();
    });
  });

  describe('renderDragPreview', () => {
    function withWidth(element:HTMLElement, width:number):HTMLElement {
      vi.spyOn(element, 'getBoundingClientRect').mockReturnValue({
        x: 0,
        y: 0,
        top: 0,
        left: 0,
        right: width,
        bottom: 64,
        width,
        height: 64,
        toJSON: vi.fn(),
      });

      return element;
    }

    it('appends a sanitized, sized clone tagged as the preview', () => {
      const target = withWidth(previewTarget(), 320);
      const container = document.createElement('div');

      renderDragPreview({ previewTarget: target, sourceElement: target, container });

      const preview = container.firstElementChild as HTMLElement;

      expect(preview).not.toBe(target);
      expect(preview.tagName).toEqual('ARTICLE');
      expect(preview.style.width).toEqual('320px');
      expect(preview.hasAttribute('data-preview')).toBe(true);
      expect(preview.hasAttribute('data-controller')).toBe(false);
    });

    it('zeroes the clone margin so source spacing utilities render no whitespace', () => {
      const target = withWidth(previewTarget(), 320);
      target.classList.add('mt-3');
      const container = document.createElement('div');

      renderDragPreview({ previewTarget: target, sourceElement: target, container });

      const preview = container.firstElementChild as HTMLElement;

      expect(preview.style.margin).toEqual('0px');
    });

    it('leaves the width unset when the preview target has no measured width', () => {
      const target = withWidth(previewTarget(), 0);
      const container = document.createElement('div');

      renderDragPreview({ previewTarget: target, sourceElement: target, container });

      const preview = container.firstElementChild as HTMLElement;

      expect(preview.style.width).toEqual('');
    });

    it('copies the originating Box density variant onto the container', () => {
      const box = document.createElement('div');
      box.className = 'Box Box--condensed';
      const target = withWidth(previewTarget(), 320);
      box.appendChild(target);

      const container = document.createElement('div');

      renderDragPreview({ previewTarget: target, sourceElement: target, container });

      expect(container.classList.contains('Box--condensed')).toBe(true);
      expect(container.classList.contains('Box--spacious')).toBe(false);
    });

    it('adds no density class when the Box carries none', () => {
      const box = document.createElement('div');
      box.className = 'Box';
      const target = withWidth(previewTarget(), 320);
      box.appendChild(target);

      const container = document.createElement('div');

      renderDragPreview({ previewTarget: target, sourceElement: target, container });

      expect(container.classList.contains('Box--condensed')).toBe(false);
      expect(container.classList.contains('Box--spacious')).toBe(false);
    });
  });
});
