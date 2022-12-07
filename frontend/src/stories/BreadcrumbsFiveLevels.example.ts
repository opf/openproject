import { ChangeDetectionStrategy, Component } from '@angular/core';
import { BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';

@Component({
  templateUrl: './BreadcrumbsFiveLevels.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbBreadcrumbsFiveLevelsExample {
  content = new BreadcrumbsContent([
    { icon: 'folder', text: 'Root folder with a long name' },
    { text: 'Second level' },
    { text: 'Third level with an even longer name' },
    { text: 'Fourth level with the longest name from all' },
    { text: 'Current level and even this one has a long name' },
  ]);
}
