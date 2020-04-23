import {Injectable} from "@angular/core";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";

@Injectable({ providedIn: 'root' })
export class BoardActionsRegistryService {

  private mapping:{ [attribute:string]:BoardActionService } = {};

  public add(attribute:string, service:BoardActionService) {
    this.mapping[attribute] = service;
  }

  public available() {
    return _.map(this.mapping, (service:BoardActionService, attribute:string) => {
      return { attribute: attribute, text: service.localizedName };
    });
  }

  public get(attribute:string):BoardActionService {
    if (this.mapping[attribute]) {
      return this.mapping[attribute];
    }

    throw(`No action service exists for ${attribute}`);
  }
}
