import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';

@Component({
  selector: 'op-content-loader',
  templateUrl: './op-content-loader.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpContentLoaderComponent implements OnInit {
  @Input() public viewBox = '0 0 400 130';

  baseUrl:string;

  ngOnInit():void {
    this.baseUrl = window.appBasePath;
  }
}
