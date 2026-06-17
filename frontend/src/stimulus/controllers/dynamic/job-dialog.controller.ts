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

import { ApplicationController } from 'stimulus-use';
import { renderStreamMessage } from '@hotwired/turbo';
import { HttpErrorResponse } from '@angular/common/http';
import { TurboHelpers } from 'core-turbo/helpers';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class AsyncJobDialogController extends ApplicationController {
    static services:ServiceKey[] = ['pathHelperService', 'notifications'];

    static values = {
        closeDialogId: String,
    };

    declare services:Promise<PickedServices<'pathHelperService'|'notifications'>>;

    declare closeDialogIdValue:string;

    initialize() {
        super.initialize();
        useAngularServices(this);
    }

    connect() {
        this.element.addEventListener('click', (e) => {
            e.preventDefault();
            void this.triggerJob();
        });
    }

    // The services must be resolved before anything that needs cleanup in the
    // finally block: their promise never settles after a disconnect, so an
    // await on it inside the try would strand the progress bar.
    private async triggerJob() {
        const { pathHelperService, notifications } = await this.services;

        TurboHelpers.showProgressBar();
        this.closePreviousDialog();

        try {
            const jobId = await this.requestJob();
            if (jobId) {
                await this.showJobModal(pathHelperService.jobStatusModalPath(jobId));
            } else {
                notifications.addError(I18n.t('js.no_job_id'));
            }
        } catch (error) {
            notifications.addError(error as string | HttpErrorResponse);
        } finally {
            TurboHelpers.hideProgressBar();
        }
    }

    closePreviousDialog() {
        if (!this.closeDialogIdValue) {
            return; // No dialog ID specified, nothing to close
        }
        const dialog = document.getElementById(this.closeDialogIdValue) as HTMLDialogElement | undefined;
        dialog?.close();
    }

    async requestJob():Promise<string> {
        const response = await fetch(this.href, {
            method: this.method,
            headers: { Accept: 'application/json' },
            credentials: 'same-origin',
        });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status.toString()}: ${response.statusText}`);
        }
        const result = await response.json() as { job_id:string };
        if (!result.job_id) {
            throw new Error(I18n.t('js.invalid_job_response'));
        }
        return result.job_id;
    }

    async showJobModal(url:string) {
        const response = await fetch(url, {
            method: 'GET',
            headers: { Accept: 'text/vnd.turbo-stream.html' },
        });
        if (response.ok) {
            renderStreamMessage(await response.text());
        } else {
            throw new Error(response.statusText);
        }
    }

    get href() {
        return (this.element as HTMLLinkElement).href;
    }

    get method() {
        return (this.element as HTMLLinkElement).dataset.jobHrefMethod ?? 'GET';
    }
}
