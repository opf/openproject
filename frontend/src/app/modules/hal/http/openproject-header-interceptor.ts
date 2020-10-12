import {
  HttpEvent,
  HttpInterceptor,
  HttpHandler,
  HttpRequest,
} from '@angular/common/http';
import {Observable} from 'rxjs';
import { Injectable } from "@angular/core";

@Injectable()
export class OpenProjectHeaderInterceptor implements HttpInterceptor {
  intercept(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const csrf_token:string|undefined = jQuery('meta[name=csrf-token]').attr('content');

    if (req.withCredentials !== false) {

      let newHeaders = req.headers
        .set('X-Authentication-Scheme', 'Session')
        .set('X-Requested-With', 'XMLHttpRequest');

      if (csrf_token) {
        newHeaders = newHeaders.set('X-CSRF-TOKEN',  csrf_token);
      }

      // Clone the request to add the new header
      const clonedRequest = req.clone({
        withCredentials: true,
        headers: newHeaders
      });

      // Pass the cloned request instead of the original request to the next handle
      return next.handle(clonedRequest);
    }

    return next.handle(req);
  }
}
