import {
  HttpEvent,
  HttpInterceptor,
  HttpHandler,
  HttpRequest,
} from '@angular/common/http';
import {Observable} from 'rxjs/observable';

export class OpenProjectHeaderInterceptor implements HttpInterceptor {
  intercept(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const csrf_token:string = jQuery('meta[name=csrf-token]').attr('content');

    // Clone the request to add the new header
    const clonedRequest = req.clone({
      headers: req.headers
        .set('X-Authentication-Scheme', 'Session')
        .set('X-Requested-With', 'XMLHttpRequest')
        .set('X-CSRF-TOKEN',  csrf_token)
    });

    // Pass the cloned request instead of the original request to the next handle
    return next.handle(clonedRequest);
  }
}
