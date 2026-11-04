import type { OpenProjectApiErrorBody } from '../../openProjectTypes';

export class OpenProjectApiError extends Error {
  responseStatus?:number;
  attributeErrors:Record<string, string>;

  constructor(message:string, responseStatus?:number, attributeErrors:Record<string, string> = {}) {
    super(message);
    this.responseStatus = responseStatus;
    this.attributeErrors = attributeErrors;
    this.name = 'OpenProjectApiError';
  }
}

function statusLineOf(response:Response):string {
  return `HTTP error! status: ${response.status} - ${response.statusText}`;
}

export function errorFromStatus(response:Response):OpenProjectApiError {
  return new OpenProjectApiError(statusLineOf(response), response.status);
}

export async function errorFromBody(response:Response):Promise<OpenProjectApiError> {
  try {
    const body = await response.json() as OpenProjectApiErrorBody;
    // A lone violation is the error itself; several are nested under a summary.
    const entries = body._embedded?.errors ?? [body];
    const messages = entries.flatMap((entry) => (entry.message ? [entry.message] : []));

    const attributeErrors:Record<string, string> = {};
    for (const entry of entries) {
      const attribute = entry._embedded?.details?.attribute;
      if (attribute && entry.message && !attributeErrors[attribute]) attributeErrors[attribute] = entry.message;
    }

    const message = messages.length > 0 ? messages.join(' ') : body.message ?? statusLineOf(response);
    return new OpenProjectApiError(message, response.status, attributeErrors);
  } catch { /* no JSON body */ }

  return errorFromStatus(response);
}
