import { Injectable } from '@angular/core';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';

export interface ITileViewEntry {
  text:string;
  attribute:string;
  icon:string;
  description:string;
  image:string;
  disabled?:boolean;
}

@Injectable({ providedIn: 'root' })
export class BoardActionsRegistryService {
  private mapping:Record<string, BoardActionService> = {};

  public add(attribute:string, service:BoardActionService):void {
    this.mapping[attribute] = service;
  }

  public available():ITileViewEntry[] {
    return Object.entries(this.mapping).map(([attribute, service]) => ({
      attribute,
      text: service.localizedName,
      icon: '',
      description: '',
      image: '',
    }));
  }

  public get(attribute:string):BoardActionService {
    if (this.mapping[attribute]) {
      return this.mapping[attribute];
    }

    throw new Error(`No action service exists for ${attribute}`);
  }
}
