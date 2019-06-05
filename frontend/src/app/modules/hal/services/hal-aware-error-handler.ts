import {ErrorHandler, Injectable} from "@angular/core";
import {ErrorResource} from "core-app/modules/hal/resources/error-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Injectable()
export class HalAwareErrorHandler extends ErrorHandler {
  private text = {
    internal_error: this.I18n.t('js.errors.internal')
  };

  constructor(private readonly I18n:I18nService) {
    super();
  }

  public handleError(error:any) {
    let message:string = this.text.internal_error;

    if (error instanceof ErrorResource) {
      console.error("Returned error resource %O", error);
      message += ` ${error.errorMessages.join("\n")}`;
    } else if (error instanceof HalResource) {
      console.error("Returned hal resource %O", error);
      message += `Resource returned ${error.name}`;
    } else {
      message = error;
    }

    super.handleError(message);
  }
}
