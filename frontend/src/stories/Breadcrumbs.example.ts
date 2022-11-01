import { ChangeDetectionStrategy, Component } from '@angular/core';
import { BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';

@Component({
  templateUrl: './Breadcrumbs.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbBreadcrumbsExample {
  content = new BreadcrumbsContent([
    { icon: 'folder', text: 'OpenProject storage' },
    { text: 'Public' },
    { text: 'Shared' },
  ]);
}
