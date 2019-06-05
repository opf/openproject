import {openprojectLegacyModule} from "core-app/openproject-legacy-app";

export class SanitizeHtmlService {

  constructor(readonly $sanitize:any) { }

  public sanitize(string:string) {
    return this.$sanitize(string);
  }
}

openprojectLegacyModule.service('sanitizeHTML', SanitizeHtmlService);
