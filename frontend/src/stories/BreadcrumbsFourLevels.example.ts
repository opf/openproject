import { ChangeDetectionStrategy, Component } from '@angular/core';
import { BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';

@Component({
  templateUrl: './BreadcrumbsFourLevels.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbBreadcrumbsFourLevelsExample {
  content = new BreadcrumbsContent([
    { icon: 'folder', text: 'Root' },
    { text: 'Second level' },
    { text: 'Third level' },
    { text: 'Current level' },
  ]);
}
