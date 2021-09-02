import {
  ChangeDetectionStrategy,
  Component, 
  Input, 
  OnInit
} from '@angular/core';

function uid() {
  return Math.random().toString(36).substring(2);
}

@Component({
  selector: 'op-content-loader',
  templateUrl: './op-content-loader.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpContentLoaderComponent implements OnInit {
  private fixedId = uid();

  idClip = `${this.fixedId}-diff`;

  idGradient = `${this.fixedId}-animated-diff`;

  idAria = `${this.fixedId}-aria`;

  @Input() animate = true;

  @Input() baseUrl = '';

  @Input() speed = 1.2;

  @Input() viewBox = '0 0 400 130';

  @Input() gradientRatio = 2;

  @Input() backgroundColor = '#f5f6f7';

  @Input() backgroundOpacity = 1;

  @Input() foregroundColor = '#eee';

  @Input() foregroundOpacity = 1;

  @Input() rtl = false;

  @Input() interval = 0.25;

  @Input() style = {};

  animationValues:string[] = [];

  clipPath:string;

  fillStyle:Record<string, unknown>;

  duration:string;

  keyTimes:string;

  rtlStyle:Record<string, unknown> | null;

  ngOnInit():void {
    this.clipPath = `url(${this.baseUrl}#${this.idClip})`;
    this.fillStyle = { fill: `url(${this.baseUrl}#${this.idGradient})` };
    this.style = this.rtl ? { ...this.style, ...{ transform: 'scaleX(-1)' } } : this.style;

    this.duration = `${this.speed}s`;
    this.keyTimes = `0; ${this.interval}; 1`;
    this.animationValues = [
      `${-this.gradientRatio}; ${-this.gradientRatio}; 1`,
      `${-this.gradientRatio / 2}; ${-this.gradientRatio / 2}; ${1 + this.gradientRatio / 2}`,
      `0; 0; ${1 + this.gradientRatio}`,
    ];
  }
}
