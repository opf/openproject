import { FetchRequestOptions } from '@hotwired/turbo/dist/types/http/fetch_request';

export function bootstrapTurboFrames():void {
  document.addEventListener('turbo:frame-render', async (event) => {
    const context = await window.OpenProject.getPluginContext();
    context.bootstrap(event.target as HTMLElement);
  });

  document.addEventListener('turbo:before-fetch-request', (event:CustomEvent) => {
    const { fetchOptions } = event.detail as { fetchOptions:FetchRequestOptions };
    const nonceEl = document.querySelector('meta[name="csp-nonce"]') as HTMLMetaElement;
    fetchOptions.headers['X-Turbolinks-Referrer'] = window.location.href;
    fetchOptions.headers['X-Turbolinks-Nonce'] = nonceEl.content;
  });
}
