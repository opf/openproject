import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';

@Injectable({ providedIn: 'root' })

export class AlternativeSearchService {
  constructor(
    readonly I18n:I18nService,
  ) { }

  public specialSearchStrings = {
    done_ratio: this.I18n.t('js.work_packages.properties.done_ratio'),
    done_ratio_alternative: this.I18n.t('js.work_packages.properties.done_ratio_alternative'),
    work: this.I18n.t('js.work_packages.properties.work'),
    work_alternative: this.I18n.t('js.work_packages.properties.work_alternative'),
    remaining_work: this.I18n.t('js.work_packages.properties.remaining_work'),
    remaining_work_alternative: this.I18n.t('js.work_packages.properties.remaining_work_alternative'),
  };

  public searchFunction = (term:string, currentItem:QueryFilterResource):boolean => {
    const alternativeNames:{ [index:string]:string } = {
      [this.specialSearchStrings.done_ratio_alternative]: this.specialSearchStrings.done_ratio,
      [this.specialSearchStrings.work_alternative]: this.specialSearchStrings.work,
      [this.specialSearchStrings.remaining_work_alternative]: this.specialSearchStrings.remaining_work,
    };

    const lowercaseSearchTerm = term.toLowerCase();
    const lowercaseCurrentItemName = currentItem.name.toLowerCase();

    const alternativeMatch = Object
      .keys(alternativeNames)
      .some((alternativeName) => {
        return alternativeName.toLowerCase().indexOf(lowercaseSearchTerm) > -1
          && currentItem.name === alternativeNames[alternativeName];
      });

    return (
      lowercaseCurrentItemName.indexOf(lowercaseSearchTerm) > -1
      || alternativeMatch
    );
  };
}
