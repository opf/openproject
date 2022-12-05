import { Pipe, PipeTransform } from '@angular/core';
import { isDirectory } from 'core-app/shared/components/file-links/file-link-icons/file-icons.helper';

@Pipe({
  name: 'sortFiles',
})
export class SortFilesPipe implements PipeTransform {
  transform<T extends { mimeType?:string, name:string }>(array:T[]):T[] {
    return array.sort((a, b):number => {
      if (isDirectory(a.mimeType) && isDirectory(b.mimeType)) {
        return a.name.localeCompare(b.name);
      }

      if (isDirectory(a.mimeType)) {
        return -1;
      }

      if (isDirectory(b.mimeType)) {
        return 1;
      }

      return a.name.localeCompare(b.name);
    });
  }
}
