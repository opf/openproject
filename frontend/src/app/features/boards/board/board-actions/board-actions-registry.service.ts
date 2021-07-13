import { Injectable } from '@angular/core';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';

@Injectable({ providedIn: 'root' })
export class BoardActionsRegistryService {
  private mapping:{ [attribute:string]:BoardActionService } = {};

  public add(attribute:string, service:BoardActionService) {
    this.mapping[attribute] = service;
  }

  public available() {
    return _.map(this.mapping, (service:BoardActionService, attribute:string) => ({
      attribute, text: service.localizedName, icon: '', description: '', image: '',
    }));
  }

  public get(attribute:string):BoardActionService {
    if (this.mapping[attribute]) {
      return this.mapping[attribute];
    }

    throw new Error(`No action service exists for ${attribute}`);
  }
}
