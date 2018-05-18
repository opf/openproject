import {BrowserModule} from '@angular/platform-browser';
import {NgModule} from '@angular/core';
import {OpenProjectModule} from 'core-app/angular4-modules';
import {AppComponent} from './app.component';
import {UpgradeModule} from '@angular/upgrade/static';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    UpgradeModule,
    OpenProjectModule
  ],
  entryComponents: [AppComponent],
  providers: [],
})
export class AppModule {

  ngDoBootstrap() {
  }

}
