import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';

@Component({
  selector: 'op-content-loader',
  templateUrl: './op-content-loader.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpContentLoaderComponent implements OnInit {
  baseUrl:string;

  ngOnInit():void {
    this.baseUrl = window.appBasePath;
  }
}
