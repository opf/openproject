import { Injectable } from '@angular/core';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';

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
  constructor(
    private bannersService:BannersService,
  ) {}

  private mapping:{ [attribute:string]:BoardActionService } = {};

  public add(attribute:string, service:BoardActionService):void {
    this.mapping[attribute] = service;
  }

  public available():ITileViewEntry[] {
    return _.map(this.mapping, (service:BoardActionService, attribute:string) => ({
      attribute,
      text: service.localizedName,
      icon: '',
      description: '',
      image: '',
      disabled: this.bannersService.eeShowBanners,
    }));
  }

  public get(attribute:string):BoardActionService {
    if (this.mapping[attribute]) {
      return this.mapping[attribute];
    }

    throw new Error(`No action service exists for ${attribute}`);
  }
}
