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
import { useMeta } from 'stimulus-use';
import * as WebAuthnJSON from '@github/webauthn-json/browser-ponyfill';
import type { CredentialRequestOptionsJSON } from '@github/webauthn-json/browser-ponyfill';

export default class WebauthnLoginController extends Controller {
  static targets = ['errorDisplay'];

  static values = {
    optionsUrl: String,
    authenticateUrl: String,
    backUrl: String,
  };

  declare readonly hasErrorDisplayTarget:boolean;
  declare readonly errorDisplayTarget:HTMLElement;
  declare readonly optionsUrlValue:string;
  declare readonly authenticateUrlValue:string;
  declare readonly backUrlValue:string;

  static metaNames = ['csrf-token'];

  declare readonly csrfToken:string;

  connect() {
    useMeta(this, { suffix: false });
  }

  async signIn(event:MouseEvent) {
    event.preventDefault();
    this.clearError();

    try {
      const response = await fetch(this.optionsUrlValue, { headers: { Accept: 'application/json' } });
      const requestOptions = await response.json() as CredentialRequestOptionsJSON['publicKey'];

      const options = WebAuthnJSON.parseRequestOptionsFromJSON({ publicKey: requestOptions });
      const credential = await WebAuthnJSON.get(options);

      this.submitCredential(credential);
    } catch (error) {
      this.displayError(error);
    }
  }

  private submitCredential(credential:unknown) {
    const form = document.createElement('form');
    form.method = 'post';
    form.action = this.authenticateUrlValue;
    form.hidden = true;

    form.append(this.hiddenField('authenticity_token', this.csrfToken));
    form.append(this.hiddenField('credential', JSON.stringify(credential)));

    if (this.backUrlValue) {
      form.append(this.hiddenField('back_url', this.backUrlValue));
    }

    document.body.append(form);
    form.submit();
  }

  private hiddenField(name:string, value:string):HTMLInputElement {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    return input;
  }

  private displayError(error:unknown) {
    const message = error instanceof DOMException && error.name === 'AbortError'
      ? I18n.t('js.webauthn_credentials.errors.aborted')
      : I18n.t('js.webauthn_credentials.errors.failed');

    if (this.hasErrorDisplayTarget) {
      this.errorDisplayTarget.innerText = message;
    }
  }

  private clearError() {
    if (this.hasErrorDisplayTarget) {
      this.errorDisplayTarget.innerText = '';
    }
  }
}
