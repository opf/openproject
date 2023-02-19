import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpContentLoaderComponent } from 'core-app/shared/components/op-content-loader/op-content-loader.component';
import { OpPrincipalLoadingComponent } from 'core-app/shared/components/op-content-loader/op-principal-loading-skeleton/op-principal-loading-skeleton.component';
import { OpWPLoadingComponent } from 'core-app/shared/components/op-content-loader/op-wp-loading-skeleton/op-wp-loading-skeleton.component';
import { ContentLoaderModule } from '@ngneat/content-loader';

@NgModule({
  declarations: [
    OpContentLoaderComponent,
    OpPrincipalLoadingComponent,
    OpWPLoadingComponent,
  ],
  exports: [
    OpContentLoaderComponent,
    OpPrincipalLoadingComponent,
    OpWPLoadingComponent,
  ],
  imports: [
    CommonModule,
    ContentLoaderModule,
  ],
})
export class OpenprojectContentLoaderModule {
}
