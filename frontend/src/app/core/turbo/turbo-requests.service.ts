import { Injectable } from '@angular/core';
import { renderStreamMessage } from '@hotwired/turbo';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

@Injectable({ providedIn: 'root' })
export class TurboRequestsService {
  constructor(
    private toast:ToastService,
  ) {

  }

  public request(url:string, init:RequestInit = {}):Promise<unknown> {
    return fetch(url, init)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return response.text();
      })
      .then((html) => renderStreamMessage(html))
      .catch((error) => this.toast.addError(error as string));
  }

  public requestStream(url:string):Promise<unknown> {
    return this.request(url, {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin',
    });
  }
}
