/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

// internal type used to filter suggestions
type FilteredSuggestions = {
  key:string;
  label:string;
  values:{ prop:string; value:string; }[];
}[];

type TokenElement = HTMLElement&{ dataset:{ role:'token', prop:string } };
type ListElement = HTMLElement&{ dataset:{ role:'list_item', prop:string } };

interface AttributeToken {
  key:string;
  label:string;
  label_with_context?:string;
  insert_as_text?:boolean;
  enabled:boolean;
};

const COMPLETION_CHARACTER = '/';
const TOKEN_REGEX = /{{([0-9A-Za-z_]+)}}/g;

// A zero-width space character, which is used
// to have a caret position after tokens
const CONTROL_SPACE = '\u200B';
// A non-breaking space inserted by some browsers to preserve multiple consecutive spaces
const NON_BREAKING_SPACE = '\u00A0';

export default class PatternInputController extends Controller {
  static targets = [
    'tokenTemplate',
    'content',
    'formInput',

    'suggestions',
    'suggestionsHeadingTemplate',
    'suggestionsDividerTemplate',
    'suggestionsItemTemplate',

    'insertAsTextTemplate',
  ];

  declare readonly tokenTemplateTarget:HTMLTemplateElement;
  declare readonly contentTarget:HTMLElement;
  declare readonly formInputTarget:HTMLInputElement;

  declare readonly suggestionsTarget:HTMLElement;
  declare readonly suggestionsHeadingTemplateTarget:HTMLTemplateElement;
  declare readonly suggestionsDividerTemplateTarget:HTMLTemplateElement;
  declare readonly suggestionsItemTemplateTarget:HTMLTemplateElement;

  declare readonly insertAsTextTemplateTarget:HTMLTemplateElement;

  static values = {
    patternInitial: String,
    suggestionsInitial: Object,
    insertAsTextTemplate: String,
  };

  declare readonly patternInitialValue:string;
  declare readonly suggestionsInitialValue:Record<string, { title:string, tokens:AttributeToken[] }>;
  declare readonly insertAsTextTemplateValue:string;

  validTokenMap:Record<string, AttributeToken> = {};
  validSuggestions:Record<string, { title:string, tokens:AttributeToken[] }> = {};
  currentRange:Range|undefined = undefined;

  connect() {
    this.validTokenMap = this.flatTokensKeyToLabelWithContext();
    this.contentTarget.innerHTML = this.toHtml(this.patternInitialValue) || ' ';
    this.populateValidSuggestions();
    this.tagInvalidTokens();
    this.clearSuggestionsFilter();
  }

  // Input field events
  input_keydown(event:KeyboardEvent) {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.updateFormInputValue();
      this.formInputTarget.form?.requestSubmit();
      return;
    }

    if (event.key === 'ArrowDown') {
      const firstSuggestion = this.suggestionsTarget.querySelector('[role="menuitem"]');
      if (firstSuggestion === null) {
        return;
      }

      (firstSuggestion as HTMLElement).focus();
      event.preventDefault();
    }
    if (event.key === 'ArrowLeft') {
      if (this.startsWithToken()) {
        this.insertSpaceIfFirstCharacter();
      }
    }
    if (event.key === 'ArrowRight') {
      if (this.endsWithToken()) {
        this.insertSpaceIfLastCharacter();
      }
    }

    this.setRange();

    // close the suggestions
    if (['Escape', 'ArrowLeft', 'ArrowRight', 'End', 'Home'].includes(event.key)) {
      this.clearSuggestionsFilter();
      this.sanitizeContent();
    }
  }

  input_change():void {
    // clean up empty tags from the input
    this.contentTarget.querySelectorAll('span').forEach((element) => { element.textContent?.trim() === '' && element.remove(); });
    this.contentTarget.querySelectorAll('br').forEach((element) => { element.remove(); });

    // show suggestions for the current word
    const word = this.currentWord();
    if (word === null) {
      this.clearSuggestionsFilter();
    } else {
      this.filterSuggestions(word);
    }

    // This resets the cursor position without changing it.
    // It is necessary because chromium based browsers try to
    // retain styling and adds an unwanted <font> tag,
    // breaking the behaviour of this component
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      const range = selection.getRangeAt(0);
      selection.removeAllRanges();
      selection.addRange(range);
    }

    this.setRange();
    this.tagInvalidTokens();
    this.sanitizeContent();
  }

  input_mouseup() {
    const selection = document.getSelection();
    if (selection?.type === 'Caret' && selection.anchorOffset === 0 && this.startsWithToken()) {
      this.insertSpaceIfFirstCharacter();
    }

    if (selection?.type === 'Caret' && this.endsWithToken()) {
      this.insertSpaceIfLastCharacter();
    }

    this.clearSuggestionsFilter();
    this.setRange();
    this.sanitizeContent();
  }

  input_focus() {
    this.setRange();
  }

  input_blur() {
    this.updateFormInputValue();
  }

  // Autocomplete events
  suggestions_select(event:PointerEvent):void {
    const target = event.currentTarget as ListElement;
    const selection = target.dataset.prop;

    // Some suggestions are configured to be inserted as text to allow for better readability.
    // As an example, take the mathematical operators of a calculated values formula.
    if (this.shouldInsertAsText(selection)) {
      const textNode = document.createTextNode(selection);
      this.insertNode(textNode);
    } else {
      const token = this.createToken(selection);
      this.insertNode(token);
    }

    this.clearSuggestionsFilter();
  }

  insert_as_text(event:PointerEvent) {
    if (!this.currentRange) { return; }

    const target = event.currentTarget as ListElement;
    const text = document.createTextNode(target.dataset.prop);
    this.insertNodeAtAppropriatePosition(text);

    this.clearSuggestionsFilter();
  }

  private flatTokensKeyToLabelWithContext():Record<string, AttributeToken> {
    return Object.entries(this.suggestionsInitialValue)
      .reduce<Record<string, AttributeToken>>((acc, [_, token_group]) => {
        token_group.tokens.forEach((t) => { acc[t.key] = t; });
        return acc;
      }, {});
  }

  private updateFormInputValue():void {
    this.formInputTarget.value = this.toBlueprint();
  }

  /**
   * Sets an internal representation of the cursor position by persisting the current `Range`
   */
  private setRange():void {
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      this.currentRange = selection.getRangeAt(0);
    }
  }

  private insertSpaceIfFirstCharacter() {
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      const range = selection.getRangeAt(0);
      // create a test range
      // select the whole content of the input
      // then set the "end" position to the current actual selection position (the caret)
      const testRange = document.createRange();
      testRange.selectNodeContents(this.contentTarget);
      testRange.setEnd(range.startContainer, range.startOffset);

      // if the resulting range is empty it is at the start of the input
      if (testRange.toString() === '') {
        const beforeToken = document.createTextNode(CONTROL_SPACE);
        const firstContent = this.contentTarget.firstChild as HTMLElement;
        this.contentTarget.insertBefore(beforeToken, firstContent);

        this.setRealCaretPositionAtNode(beforeToken, 'before');
      }
    }
  }

  private insertSpaceIfLastCharacter():void {
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      const range = selection.getRangeAt(0);
      // create a test range
      // select the whole content of the input
      // then set the "start" position to the current actual selection position (the caret)
      const testRange = document.createRange();
      testRange.selectNodeContents(this.contentTarget);
      testRange.setStart(range.endContainer, range.endOffset);

      // if the resulting range is empty, it is at the end of the input
      if (testRange.toString() === '') {
        const afterToken = document.createTextNode(CONTROL_SPACE);
        this.contentTarget.appendChild(afterToken);

        this.setRealCaretPositionAtNode(afterToken);
      }
    }
  }

  private setRealCaretPositionAtNode(target:Node, position:'before'|'after' = 'after'):void {
    const selection = document.getSelection();
    if (selection === null) { return; }

    const postRange = document.createRange();
    if (position === 'after') {
      if (this.isToken(target) && target.nextSibling?.textContent === CONTROL_SPACE) {
        postRange.setStartAfter(target.nextSibling);
      } else if (this.isToken(target) && this.isText(target.nextSibling)) {
        postRange.setStart(target.nextSibling, 1);
      } else {
        postRange.setStartAfter(target);
      }
    } else {
      postRange.setStartBefore(target);
    }

    selection.removeAllRanges();
    selection.addRange(postRange);
  }

  private endsWithToken():boolean {
    return this.contentTarget.innerHTML.endsWith('>');
  }

  private startsWithToken():boolean {
    return this.contentTarget.innerHTML.startsWith('<');
  }

  private replaceToken(node:Node, token:TokenElement):void {
    if (this.isText(node) && token.nextSibling?.textContent === CONTROL_SPACE) {
      token.nextSibling.remove();
    }

    token.replaceWith(node);
    this.setRealCaretPositionAtNode(node);
    this.updateFormInputValue();
    this.setRange();
  }

  private insertNodeAtCurrentRange(node:Node) {
    if (!this.currentRange) { return; }

    const targetNode = this.currentRange.startContainer;
    const targetOffset = this.currentRange.startOffset;
    const textContent = targetNode.textContent;

    if (textContent === null) { return; }

    let pos = targetOffset - 1;
    while (pos > -1 && textContent.charAt(pos) !== COMPLETION_CHARACTER) { pos -= 1; }

    const wordRange = document.createRange();
    wordRange.setStart(targetNode, pos);
    wordRange.setEnd(targetNode, targetOffset);

    wordRange.deleteContents();
    wordRange.insertNode(node);

    this.sanitizeContent();
    this.setRealCaretPositionAtNode(node);
    this.updateFormInputValue();
    this.setRange();
  }

  private currentWord():string|null {
    const selection = document.getSelection();
    if (selection === null) { return null; }

    const anchor = selection.anchorNode;
    if (anchor === null) { return null; }

    const parent = anchor.parentNode;
    if (parent === null) { return null; }

    const textContent = anchor.textContent;
    if (textContent === null) { return null; }

    if (this.isToken(parent)) {
      const token = this.validTokenMap[parent.dataset.prop];
      const prefix = token.label_with_context?.replace(token.label, '');
      const start = prefix && textContent.startsWith(prefix) ? prefix.length : 0;

      return textContent.slice(start, selection.anchorOffset);
    }

    const posKey = textContent.lastIndexOf(COMPLETION_CHARACTER);
    if (posKey === -1) { return null; }

    // The key character is only considered valid if directly followed by a non-whitespace character.
    const textAfterKey = textContent.slice(posKey + 1, selection.anchorOffset);
    return textAfterKey.startsWith(' ') ? null : textAfterKey;
  }

  private clearSuggestionsFilter():void {
    this.suggestionsTarget.innerHTML = '';
    this.suggestionsTarget.classList.add('d-none');
  }

  private filterSuggestions(word:string):void {
    this.clearSuggestionsFilter();
    this.suggestionsTarget.classList.remove('d-none');

    const filtered = this.getFilteredSuggestionsData(word.toLowerCase());

    // insert the HTML
    filtered.forEach((group, idx) => {
      const groupHeader = this.suggestionsHeadingTemplateTarget.content.cloneNode(true);

      if (this.isDocumentFragmentNode(groupHeader)) {
        const headerElement = groupHeader.querySelector('h2');
        if (headerElement) {
          headerElement.innerText = group.label;
        }

        this.suggestionsTarget.appendChild(groupHeader);
      }

      group.values.forEach((suggestion) => {
        const suggestionTemplate = this.suggestionsItemTemplateTarget.content.cloneNode(true);
        if (!this.isDocumentFragmentNode(suggestionTemplate)) { return; }

        const suggestionItem = suggestionTemplate.firstElementChild;
        if (this.isElement(suggestionItem)) {
          suggestionItem.dataset.prop = suggestion.prop;
          this.setSuggestionText(suggestionItem, suggestion.value);
          this.suggestionsTarget.appendChild(suggestionItem);
        }
      });

      const groupDivider = this.suggestionsDividerTemplateTarget.content.cloneNode(true) as HTMLElement;
      if (idx < filtered.length - 1) {
        this.suggestionsTarget.appendChild(groupDivider);
      }
    });

    if (this.suggestionsTarget.childNodes.length === 0) {
      this.appendInsertAsTextElement(word);
    }
  }

  private appendInsertAsTextElement(word:string):void {
    const template = this.insertAsTextTemplateTarget.content.cloneNode(true) as DocumentFragment;
    const item = template.firstElementChild;
    if (!this.isListItem(item)) { return; }

    const textElement = item.querySelector('span');
    if (textElement === null) { return; }

    item.dataset.prop = word;
    textElement.innerText = this.insertAsTextTemplateValue.replace('%{word}', word);
    this.suggestionsTarget.appendChild(item);
  }

  private setSuggestionText(suggestionItem:HTMLElement, value:string) {
    const textContainer = suggestionItem.querySelector('span');
    if (textContainer) {
      textContainer.innerText = value;
    } else {
      throw new Error('suggestion template does not have a span to hold the suggestion value');
    }
  }

  private getFilteredSuggestionsData(word:string):FilteredSuggestions {
    return Object.keys(this.validSuggestions).map((key) => {
      const group = this.validSuggestions[key];
      return {
        key,
        label: group.title,
        values: group.tokens
          .filter((token) => token.key.includes(word) || token.label.toLowerCase().includes(word) || word === '*')
          .map((token) => ({ prop: token.key, value: token.label })),
      };
    }).filter((group) => group.values.length > 0);
  }

  private populateValidSuggestions():void {
    for (const key of Object.keys(this.suggestionsInitialValue)) {
      const group = this.suggestionsInitialValue[key];
      this.validSuggestions[key] = {
        title: group.title,
        tokens: group.tokens.filter((token) => token.enabled),
      };
    }
  }

  private tagInvalidTokens():void {
    this.contentTarget.querySelectorAll('[data-role="token"]').forEach((element:TokenElement) => {
      if (this.isSuggestable(element.dataset.prop)) {
        this.setStyle(element, 'accent');
      } else {
        this.setStyle(element, 'danger');
      }
    });
  }

  private isSuggestable(token:string):boolean {
    return Object.keys(this.validTokenMap).some((key) => this.validTokenMap[key].enabled && token === key);
  }

  private setStyle(token:TokenElement, style:'accent'|'danger'|'secondary'):void {
    switch (style) {
      case 'accent':
        token.classList.remove('Label--danger', 'Label--secondary');
        token.classList.add('Label--accent');
        break;
      case 'danger':
        token.classList.remove('Label--accent', 'Label--secondary');
        token.classList.add('Label--danger');
        break;
      case 'secondary':
        token.classList.remove('Label--accent', 'Label--danger');
        token.classList.add('Label--secondary');
        break;
      default:
        throw new Error('Invalid label style');
    }
  }

  private createToken(key:string):TokenElement {
    const templateTarget = this.tokenTemplateTarget.content.cloneNode(true) as DocumentFragment;
    const contentElement = templateTarget.firstElementChild as TokenElement;
    contentElement.dataset.prop = key;
    contentElement.innerText = this.tokenText(key);
    return contentElement;
  }

  private sanitizeContent():void {
    this.contentTarget.childNodes.forEach((node) => {
      if (this.isToken(node)) {
        const key = node.dataset.prop;
        if (this.isSuggestable(key)) {
          this.setStyle(node, 'accent');
        } else {
          this.setStyle(node, 'danger');
        }

        if (node.textContent !== this.tokenText(key)) {
          if (this.containsCursor(node)) {
            this.setStyle(node, 'secondary');
          } else {
            node.innerText = this.tokenText(key);
          }
        }

        const follower = node.nextSibling;
        if (follower === null) {
          node.after(document.createTextNode(CONTROL_SPACE));
        } else {
          if (this.isToken(follower)) {
            node.after(document.createTextNode(CONTROL_SPACE));
          }

          if (this.isText(follower) && !this.isWhitespaceOrControlSpace(follower.wholeText[0])) {
            node.after(document.createTextNode(CONTROL_SPACE));
          }
        }
      }
    });
  }

  private tokenText(key:string):string {
    const token = this.validTokenMap[key];

    if (!token) {
      return key;
    }

    if (token.label_with_context) {
      if (token.key.startsWith('parent_') || token.key.startsWith('project_')) {
        return token.label_with_context;
      }
    }

    return token.label;
  }

  private toHtml(blueprint:string):string {
    let html = blueprint.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    html = this.insertControlSpaces(html);
    return html.replace(TOKEN_REGEX, (_, token:string) => this.createToken(token).outerHTML);
  }

  private insertControlSpaces(blueprint:string):string {
    const regex = TOKEN_REGEX;
    let match = regex.exec(blueprint);
    const controlSpacesIndices = [];

    while (match !== null) {
      const endOfMatch = match.index + match[0].length;
      if (endOfMatch < match.input.length && !this.isWhitespaceOrControlSpace(match.input[endOfMatch])) {
        // add a control space when the token is not followed by whitespace
        controlSpacesIndices.push(endOfMatch);
      }

      match = regex.exec(blueprint);
    }

    return controlSpacesIndices
      .reverse()
      .reduce((acc, index) => {
        return `${acc.slice(0, index)}${CONTROL_SPACE}${acc.slice(index)}`;
      }, blueprint);
  }

  private toBlueprint():string {
    let result = '';
    this.contentTarget.childNodes.forEach((node:ChildNode) => {
      if (this.isText(node)) {
        result += node.textContent ?? '';
      } else if (this.isToken(node)) {
        result += `{{${node.dataset.prop}}}`;
      }
    });

    // remove any padding whitespaces and control spaces, which were used for
    // usability, and non-breaking spaces inserted by some browsers
    return result.trim()
      .replace(new RegExp(CONTROL_SPACE, 'g'), '')
      .replace(new RegExp(NON_BREAKING_SPACE, 'g'), ' ');
  }

  private containsCursor(node:Node):boolean {
    if (!this.currentRange) { return false; }

    return node === this.currentRange.startContainer.parentNode;
  }

  private isToken(node:Node|null):node is TokenElement {
    return this.isElement(node) && node.dataset.role === 'token';
  }

  private isListItem(node:Node|null):node is ListElement {
    return this.isElement(node) && node.dataset.role === 'list_item';
  }

  private isDocumentFragmentNode(node:Node|null):node is DocumentFragment {
    return node !== null && node.nodeType === Node.DOCUMENT_FRAGMENT_NODE;
  }

  private isText(node:Node|null):node is Text {
    return node !== null && node.nodeType === Node.TEXT_NODE;
  }

  private isElement(node:Node|null):node is HTMLElement {
    return node !== null && node.nodeType === Node.ELEMENT_NODE;
  }

  private isWhitespaceOrControlSpace(value:string|undefined|null):boolean {
    if (value?.length !== 1) { return false; }

    return new RegExp(`[${CONTROL_SPACE}\\s]`).test(value);
  }

  private insertNode(node:Node) {
    if (!this.currentRange) {
      this.contentTarget.appendChild(node);
      return;
    }

    this.insertNodeAtAppropriatePosition(node);
  }

  private insertNodeAtAppropriatePosition(node:Node) {
    if (!this.currentRange) { return; }

    const parentNode = this.currentRange.startContainer.parentNode;
    if (this.isToken(parentNode)) {
      this.replaceToken(node, parentNode);
    } else {
      this.insertNodeAtCurrentRange(node);
    }
  }

  private shouldInsertAsText(tokenKey:string):boolean {
    return Object.values(this.suggestionsInitialValue).some(
      (group) =>
        group.tokens.some((token) => token.key === tokenKey && token.insert_as_text),
    );
  }
}
