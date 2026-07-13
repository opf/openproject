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

import {Controller} from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';
import {useMeta} from 'stimulus-use';

export default class extends Controller {
    static targets = ['button', 'progressBanner', 'urlInput', 'tokenInput'];

    declare readonly buttonTargets:HTMLButtonElement[];
    declare readonly progressBannerTarget:HTMLButtonElement;
    declare readonly urlInputTarget:HTMLInputElement;
    declare readonly tokenInputTarget:HTMLInputElement;

    static metaNames = ['csrf-token'];
    declare readonly csrfToken:string;

    static values = {
        url: String,
        id: String
    };

    declare urlValue:string;
    declare idValue:string;

    connect():void {
        useMeta(this, {suffix: false});
        document.addEventListener('turbo:before-cache', this.clearBeforeCache);
    }

    disconnect():void {
        document.removeEventListener('turbo:before-cache', this.clearBeforeCache);
    }

    private clearBeforeCache = ():void => {
        this.element.querySelectorAll('input').forEach((input:HTMLInputElement) => {
            input.value = '';
        });
    };

    disableButtons():void {
        this.buttonTargets.forEach(button => {
            button.disabled = true;
        });
    }

    async testConnection(event:Event):Promise<void> {
        event.preventDefault();

        const url = this.urlInputTarget.value.trim();
        const token = this.tokenInputTarget?.value.trim();

        this.disableButtons();
        this.progressBannerTarget.hidden = false;

        try {
            const formData = new FormData();
            formData.append('url', url);
            if (token) {
                formData.append('personal_access_token', token);
            }
            if (this.idValue) {
                formData.append('id', this.idValue);
            }

            const response = await fetch(this.urlValue, {
                method: 'POST',
                body: formData,
                headers: {
                    'Accept': 'text/vnd.turbo-stream.html',
                    'X-CSRF-Token': this.csrfToken,
                },
            });

            Turbo.renderStreamMessage(await response.text());
        } catch (error) {
            console.error(error);
        } finally {
            this.buttonTargets.forEach(button => {
                button.disabled = false;
            });
            this.progressBannerTarget.hidden = true;
        }
    }
}
