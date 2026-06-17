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
import {HttpErrorResponse} from '@angular/common/http';
import {useAngularServices, type PickedServices, type ServiceKey} from 'core-stimulus/mixins/use-angular-services';

export default class extends Controller {
    static services:ServiceKey[] = ['notifications'];

    static targets = ['finished', 'poll'];
    static values = {
        url: String
    };

    private pollingInterval = 3000;

    declare services:Promise<PickedServices<'notifications'>>;

    declare urlValue:string;

    interval?:ReturnType<typeof setInterval>;

    initialize() {
        useAngularServices(this);
    }

    pollTargetConnected() {
        this.interval ??= setInterval(() => {
            this.reload()
                .catch((error) => { void this.handleError(error as HttpErrorResponse); });
        }, this.pollingInterval);
    }

    finishedTargetConnected() {
        if (this.interval !== undefined) {
            clearInterval(this.interval);
            this.interval = undefined;
        }
    }

    disconnect() {
        super.disconnect();
        this.finishedTargetConnected();
    }

    private async reload() {
        const url = this.urlValue;
        const response = await fetch(url, {
            method: 'GET',
            headers: {Accept: 'text/vnd.turbo-stream.html'}
        });
        if (response.ok) {
            Turbo.renderStreamMessage(await response.text());
        } else {
            throw new Error(response.statusText);
        }
    }

    private async handleError(error:HttpErrorResponse) {
        const {notifications} = await this.services;
        notifications.addError(error);
    }
}