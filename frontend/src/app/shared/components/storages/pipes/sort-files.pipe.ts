import { Pipe, PipeTransform } from '@angular/core';

import { isDirectory } from 'core-app/shared/components/storages/functions/storages.functions';
import { IFileLinkOriginData } from 'core-app/core/state/file-links/file-link.model';

@Pipe({
  name: 'sortFiles',
})
export class SortFilesPipe implements PipeTransform {
  transform<T extends IFileLinkOriginData>(array:T[]):T[] {
    return array.sort((a, b):number => {
      if (isDirectory(a) && isDirectory(b)) {
        return a.name.localeCompare(b.name);
      }

      if (isDirectory(a)) {
        return -1;
      }

      if (isDirectory(b)) {
        return 1;
      }

      return a.name.localeCompare(b.name);
    });
  }
}
