import {BrowserModule} from '@angular/platform-browser';
import {NgModule} from '@angular/core';
import {AppComponent} from './app.component';
import {UpgradeModule} from '@angular/upgrade/static';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    UpgradeModule,
  ],
  entryComponents: [AppComponent],
  providers: [],
})
export class AppModule {

  ngDoBootstrap() {
  }

}
