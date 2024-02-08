import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';

@Injectable({ providedIn: 'root' })

export class AlternativeSearchService {
  constructor(
    readonly I18n:I18nService,
  ) { }

  private specialSearchStrings = {
    percentComplete: this.I18n.t('js.work_packages.properties.percentComplete'),
    percentCompleteAlternative: this.I18n.t('js.work_packages.properties.percentCompleteAlternative'),
    work: this.I18n.t('js.work_packages.properties.work'),
    workAlternative: this.I18n.t('js.work_packages.properties.workAlternative'),
    remainingWork: this.I18n.t('js.work_packages.properties.remainingWork'),
    remainingWorkAlternative: this.I18n.t('js.work_packages.properties.remainingWorkAlternative'),
  };

  private alternativeNames:{ [index:string]:string } = {
    [this.specialSearchStrings.percentCompleteAlternative]: this.specialSearchStrings.percentComplete,
    [this.specialSearchStrings.workAlternative]: this.specialSearchStrings.work,
    [this.specialSearchStrings.remainingWorkAlternative]: this.specialSearchStrings.remainingWork,
  };

  public searchFunction = (term:string, currentItem:QueryFilterResource):boolean => {
    const lowercaseSearchTerm = term.toLowerCase();
    const lowercaseCurrentItemName = currentItem.name.toLowerCase();

    const alternativeMatch = Object
      .keys(this.alternativeNames)
      .some((alternativeName) => {
        return alternativeName.toLowerCase().includes(lowercaseSearchTerm)
          && currentItem.name === this.alternativeNames[alternativeName];
      });

    return lowercaseCurrentItemName.includes(lowercaseSearchTerm)
      || alternativeMatch;
  };
}
