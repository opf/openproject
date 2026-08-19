import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerInputCaptionStreamAction() {
  StreamActions.addInputCaption = function addInputCaptionAction(this:StreamElement) {
    const target = document.querySelector(this.target);
    if (target) {
      const formControl = (target as HTMLElement).closest('.FormControl')!;

      if (this.getAttribute('clean_other_captions') === 'true') {
        formControl
          .querySelectorAll('.FormControl-caption')
          .forEach((caption) => caption.remove());
      }

      const caption = this.getAttribute('caption');
      if (caption && caption !== '') {
        const span = document.createElement('span');
        span.className = 'FormControl-caption';
        span.innerText = caption;
        formControl.append(span);
      }
    }
  };
}
