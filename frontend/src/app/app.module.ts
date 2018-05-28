import {BrowserModule} from '@angular/platform-browser';
import {NgModule} from '@angular/core';
import {OpenProjectModule} from 'core-app/angular4-modules';
import {UpgradeModule} from '@angular/upgrade/static';

@NgModule({
  declarations: [
  ],
  imports: [
    BrowserModule,
    UpgradeModule,
    OpenProjectModule
  ],
  entryComponents: [],
  providers: [],
})
export class AppModule {

  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap() {
    // required
  }

}
