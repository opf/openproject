import { HttpHeaders, HttpParams } from "@angular/common/http";

export type HTTPSupportedMethods = 'get'|'post'|'put'|'patch'|'delete';

export interface HTTPClientOptions {
  body?:any;
  headers?:HTTPClientHeaders;
  observe?:any;
  params?:HTTPClientParams;
  reportProgress?:boolean;
  withCredentials?:boolean;
  responseType:any;
}

export type HTTPClientParamMap = { [key:string]:any };
export type HTTPClientHeaders = HttpHeaders|HTTPClientParamMap;
export type HTTPClientParams = HttpParams|HTTPClientParamMap;