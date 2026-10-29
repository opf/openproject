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

/* eslint-disable @angular-eslint/no-input-rename */

import {
  afterRenderEffect,
  booleanAttribute,
  ComponentRef,
  computed,
  DestroyRef,
  Directive,
  effect,
  ElementRef,
  inject,
  input,
  signal,
  untracked,
  ViewContainerRef,
} from '@angular/core';
import { attributeTokenList, ensureId, generateId, isTextCutOffOrHidden } from 'core-app/shared/helpers/dom-helpers';
import { OpTooltipComponent, TooltipType } from './tooltip.component';
import { TooltipDirection } from './tooltip-direction';

type ReferenceAttribute = 'aria-labelledby' | 'aria-describedby';
type OwnedAttribute = 'aria-label' | 'aria-description';

interface HostAria {
  tooltip:{ type:TooltipType, text:string }|null;
  'aria-label':string|null;
  'aria-description':string|null;
}

const REFERENCE_ATTRIBUTES:Record<TooltipType, ReferenceAttribute> = {
  label: 'aria-labelledby',
  description: 'aria-describedby',
};

const presence = (value?:string) => (value === undefined || value === '' ? null : value);

@Directive({ selector: '[opTooltip]' })
export class OpTooltipDirective {
  readonly label = input<string>();
  readonly description = input<string>();
  readonly showTooltip = input(true, { transform: booleanAttribute });
  readonly tooltipId = input(generateId('tooltip'));
  readonly tooltipDirection = input<TooltipDirection>('s', { alias: 'tooltip-direction' });
  /**
   * Opens the tooltip only while this text is cut off or hidden (not rendered or visually hidden),
   * for a label that repeats text the control shows at some widths. Empty for the host, a selector
   * within the host, or an element. Inline text only counts while hidden, so pass the ancestor that
   * cuts it off; see {@link isTextCutOffOrHidden}.
   */
  readonly tooltipWhenTruncated = input<HTMLElement|string>();

  private readonly viewContainer = inject(ViewContainerRef);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
  private readonly hostId = signal(this.host.id);

  private readonly hostAria = computed<HostAria>(() => {
    const label = presence(this.label());
    const description = presence(this.description());

    if (!this.showTooltip() || (!label && !description)) {
      return { tooltip: null, 'aria-label': label, 'aria-description': description };
    }

    if (description) {
      return { tooltip: { type: 'description', text: description }, 'aria-label': label, 'aria-description': null };
    }

    return { tooltip: { type: 'label', text: label! }, 'aria-label': null, 'aria-description': null };
  });

  private tooltipRef:ComponentRef<OpTooltipComponent>|null = null;
  private appliedTooltipId:string|null = null;
  private readonly displacedValues = new Map<OwnedAttribute, string|null>();

  constructor() {
    const observer = new MutationObserver(() => this.hostId.set(this.host.id));
    observer.observe(this.host, { attributeFilter: ['id'] });
    inject(DestroyRef).onDestroy(() => observer.disconnect());

    effect(() => this.renderTooltip());
    afterRenderEffect({ write: () => this.reconcileHost() });
  }

  private renderTooltip() {
    const { tooltip } = this.hostAria();

    if (!tooltip) {
      this.tooltipRef?.destroy();
      this.tooltipRef = null;
      return;
    }

    if (!this.tooltipRef) {
      this.tooltipRef = untracked(() => this.viewContainer.createComponent(OpTooltipComponent));
      (this.tooltipRef.location.nativeElement as HTMLElement)
        .addEventListener('beforetoggle', (event) => this.suppressWhileTextFits(event));
    }
    this.tooltipRef.setInput('forId', this.hostId() || ensureId(this.host));
    this.tooltipRef.setInput('tooltipId', this.tooltipId());
    this.tooltipRef.setInput('type', tooltip.type);
    this.tooltipRef.setInput('direction', this.tooltipDirection());
    this.tooltipRef.setInput('text', tooltip.text);
  }

  private suppressWhileTextFits(event:ToggleEvent) {
    const text = this.truncatableText();
    if (event.newState === 'open' && text && !isTextCutOffOrHidden(text)) {
      event.preventDefault();
    }
  }

  private truncatableText():HTMLElement|null {
    const target = this.tooltipWhenTruncated();
    if (target === undefined || target instanceof HTMLElement) {
      return target ?? null;
    }

    return target === '' ? this.host : this.host.querySelector<HTMLElement>(target);
  }

  private reconcileHost() {
    const hostAria = this.hostAria();
    const tooltipId = this.tooltipId();
    const wanted = hostAria.tooltip && REFERENCE_ATTRIBUTES[hostAria.tooltip.type];
    const ownedIds = new Set([this.appliedTooltipId, tooltipId].filter((id) => id !== null));

    Object.values(REFERENCE_ATTRIBUTES).forEach((attribute) => {
      ownedIds.forEach((id) => {
        if (attribute !== wanted || id !== tooltipId) {
          this.removeReference(attribute, id);
        }
      });
    });

    if (wanted) {
      attributeTokenList(this.host, wanted).add(tooltipId);
    }
    this.appliedTooltipId = wanted ? tooltipId : null;

    this.applyOwned('aria-label', hostAria['aria-label']);
    this.applyOwned('aria-description', hostAria['aria-description']);
  }

  private removeReference(attribute:ReferenceAttribute, id:string) {
    const tokens = attributeTokenList(this.host, attribute);
    if (!tokens.contains(id)) {
      return;
    }

    tokens.remove(id);
    if (tokens.length === 0) {
      this.host.removeAttribute(attribute);
    }
  }

  private applyOwned(attribute:OwnedAttribute, value:string|null) {
    if (value !== null) {
      if (!this.displacedValues.has(attribute)) {
        this.displacedValues.set(attribute, this.host.getAttribute(attribute));
      }
      this.host.setAttribute(attribute, value);
      return;
    }

    if (!this.displacedValues.has(attribute)) {
      return;
    }

    const displaced = this.displacedValues.get(attribute)!;
    this.displacedValues.delete(attribute);
    if (displaced === null) {
      this.host.removeAttribute(attribute);
    } else {
      this.host.setAttribute(attribute, displaced);
    }
  }
}
