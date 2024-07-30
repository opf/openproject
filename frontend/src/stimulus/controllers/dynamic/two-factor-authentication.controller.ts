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
import * as WebAuthnJSON from '@github/webauthn-json/browser-ponyfill';
import QrCreator from 'qr-creator';

export default class TwoFactorAuthenticationController extends Controller {
  static targets = ['resendOptions', 'qrCodeElement', 'webauthnCredential', 'errorDisplay'];

  declare readonly resendOptionsTarget:HTMLElement;
  declare readonly webauthnCredentialTarget:HTMLInputElement;
  declare readonly errorDisplayTarget:HTMLElement;

  async onVerifyDevice(event:SubmitEvent) {
    const form = event.target as HTMLFormElement;
    const data = form.dataset;

    // We are not in the context of verifying a WebAuthn device, so we can just submit the form
    if (data.deviceType !== 'webauthn') {
      return true;
    }

    this.clearError();
    event.preventDefault();

    try {
      const verifyOptionsRequest = await fetch(data.challengeUrl as string);
      const verifyOptions = await verifyOptionsRequest.text();

      const options = WebAuthnJSON.parseRequestOptionsFromJSON({
        publicKey: JSON.parse(verifyOptions),
      });

      const credential = await WebAuthnJSON.get(options);

      if (credential) {
        this.webauthnCredentialTarget.value = JSON.stringify(credential);
        form.submit();
      }

      return true;
    } catch (error) {
      this.displayError(error);
      return false;
    }
  }

  async onCreateDevice(event:SubmitEvent) {
    const form = event.target as HTMLFormElement;
    const data = form.dataset;

    // We are not in the context of adding a WebAuthn device, so we can just submit the form
    if (data.deviceType !== 'webauthn') {
      return true;
    }

    this.clearError();
    event.preventDefault();

    try {
      const createOptionsRequest = await fetch(data.challengeUrl as string);
      const createOptions = await createOptionsRequest.text();

      const options = WebAuthnJSON.parseCreationOptionsFromJSON({
        publicKey: JSON.parse(createOptions),
      });

      const credential = await WebAuthnJSON.create(options);

      if (credential) {
        this.webauthnCredentialTarget.value = JSON.stringify(credential);
        form.submit();
      }

      return true;
    } catch (error) {
      this.displayError(error);
      return false;
    }
  }

  qrCodeElementTargetConnected(target:HTMLElement) {
    QrCreator.render(
      {
        text: target.dataset.value as string,
        radius: 0,
        ecLevel: 'H',
        fill: '#222222',
        background: '#FFFFFF',
        size: 250,
      },
      target,
    );
  }

  print(evt:MouseEvent) {
    evt.preventDefault();
    window.print();
  }

  toggleResendOptions(evt:MouseEvent) {
    evt.preventDefault();
    this.resendOptionsTarget.hidden = !this.resendOptionsTarget.hidden;
  }

  private displayError(error:DOMException) {
    let errorMessage = `Error registering device: ${error.message}`;
    if (error.name === 'AbortError') {
      errorMessage = I18n.t('js.two_factor_authentication.errors.aborted');
    }
    this.errorDisplayTarget.innerText = errorMessage;
  }

  private clearError() {
    this.errorDisplayTarget.innerText = '';
  }
}
