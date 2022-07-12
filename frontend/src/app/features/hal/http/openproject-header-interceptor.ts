import {
  HttpEvent, HttpHandler, HttpInterceptor, HttpRequest,
} from '@angular/common/http';
import { Observable } from 'rxjs';
import { Injectable } from '@angular/core';

export const EXTERNAL_REQUEST_HEADER = 'X-External-Request';

@Injectable()
export class OpenProjectHeaderInterceptor implements HttpInterceptor {
  intercept(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const withCredentials = req.headers.get(EXTERNAL_REQUEST_HEADER) !== 'true';

    if (withCredentials) {
      return this.handleAuthenticatedRequest(req, next);
    } else {
      return this.handleExternalRequest(req, next);
    }
  }

  private handleExternalRequest(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    // Clone the request to add the new header
    const clonedRequest = req.clone({
      withCredentials: false,
      headers: req.headers.delete(EXTERNAL_REQUEST_HEADER),
    });

    return next.handle(clonedRequest);
  }

  private handleAuthenticatedRequest(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const csrf_token:string|undefined = jQuery('meta[name=csrf-token]').attr('content');

    let newHeaders = req.headers
      .set('X-Authentication-Scheme', 'Session')
      .set('X-Requested-With', 'XMLHttpRequest');

    if (csrf_token) {
      newHeaders = newHeaders.set('X-CSRF-TOKEN', csrf_token);
    }

    // Clone the request to add the new header
    const clonedRequest = req.clone({
      withCredentials: true,
      headers: newHeaders,
    });

    // Pass the cloned request instead of the original request to the next handle
    return next.handle(clonedRequest);
  }
}
