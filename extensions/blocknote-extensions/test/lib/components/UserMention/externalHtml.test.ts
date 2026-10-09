// @vitest-environment jsdom
import { describe, expect, it } from 'vitest';
import {
  buildUserMentionStoredDOM,
  userMentionTag,
  parseUserMentionExternalHTML,
} from '../../../../lib/components/UserMention/externalHtml';

const judith = { userId: '5', name: 'Judith Roth' };

describe('user mention external HTML', () => {
  it('builds the canonical tag', () => {
    expect(userMentionTag(judith))
      .toBe('<mention class="mention" data-id="5" data-type="user" data-text="@Judith Roth">@Judith Roth</mention>');
  });

  it('wraps the tag as text for the stored markdown', () => {
    const wrapper = buildUserMentionStoredDOM(judith, document);

    expect(wrapper.children).toHaveLength(0);
    expect(wrapper.textContent).toBe(userMentionTag(judith));
  });

  it('parses its own wrapper back', () => {
    expect(parseUserMentionExternalHTML(buildUserMentionStoredDOM(judith, document)))
      .toEqual(judith);
  });

  it('parses a mention copied from a CKEditor field', () => {
    const host = document.createElement('div');
    host.innerHTML = userMentionTag(judith);

    expect(parseUserMentionExternalHTML(host.firstElementChild as HTMLElement)).toEqual(judith);
  });

  it('reads back a name with quotes, ampersands and angle brackets from its own tag', () => {
    const ann = { userId: '9', name: 'Ann "A&B" <Lee>' };
    const host = document.createElement('div');
    host.innerHTML = userMentionTag(ann);

    expect(parseUserMentionExternalHTML(host.firstElementChild as HTMLElement)).toEqual(ann);
  });

  it('leaves a type-only wrapper to the mention inside it', () => {
    const wrapper = document.createElement('span');
    wrapper.setAttribute('data-inline-content-type', 'openProjectUserMention');

    expect(parseUserMentionExternalHTML(wrapper)).toBeUndefined();
  });

  it('ignores group and work package mentions', () => {
    const host = document.createElement('div');
    host.innerHTML = '<mention class="mention" data-id="3" data-type="group" data-text="@Team">@Team</mention>';

    expect(parseUserMentionExternalHTML(host.firstElementChild as HTMLElement)).toBeUndefined();
  });

  it('ignores a user mention without an id', () => {
    const host = document.createElement('div');
    host.innerHTML = '<mention class="mention" data-type="user" data-text="@Judith Roth">@Judith Roth</mention>';

    expect(parseUserMentionExternalHTML(host.firstElementChild as HTMLElement)).toBeUndefined();
  });
});
