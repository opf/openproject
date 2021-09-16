import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpContentLoaderComponent } from 'core-app/shared/components/op-content-loader/op-content-loader.component';
import { ContentLoaderModule } from '@ngneat/content-loader';

@NgModule({
  declarations: [
    OpContentLoaderComponent,
  ],
  exports: [
    OpContentLoaderComponent,
  ],
  imports: [
    CommonModule,
    ContentLoaderModule,
  ],
})
export class OpenprojectContentLoaderModule {
}
