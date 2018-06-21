import {BrowserModule} from '@angular/platform-browser';
import {NgModule} from '@angular/core';
import {OpenProjectModule} from 'core-app/angular4-modules';

@NgModule({
  declarations: [
  ],
  imports: [
    BrowserModule,
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
