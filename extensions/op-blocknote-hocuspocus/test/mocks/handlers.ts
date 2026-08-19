import { http, HttpResponse } from 'msw';

export const handlers = [
  // Dynamic handler supporting multiple test cases for different status codes controlled via document ID.
  // This also ensures that the Authorization header and Content-type are sent as well.
  http.get<{ protocol: string, host: string, id: string }>(':protocol://:host/api/v3/documents/:id', (request) => {
    if (!request.request.headers.get('Authorization') || request.params.id == '401') {
      return HttpResponse.json({ error: 'unauthorized' }, { status: 401 });
    }

    if (request.request.headers.get('Content-type') != 'application/json') {
      return HttpResponse.json({ error: 'unexpected content type' }, { status: 415 });
    }

    if (request.params.id == '404') {
      return HttpResponse.json({ error: 'not found' }, { status: 404 });
    }

    return HttpResponse.json({
      id: request.params.id,
      title: 'Some existing document',
      __echo: {
        url: request.request.url,
        xForwardedProtoHeader: request.request.headers.get("X-Forwarded-Proto")
      }
    });
  }),
];
