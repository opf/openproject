import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['authorName'];

  static values = {
    authorId: Number,
  };

  declare authorIdValue:number;

  declare authorNameTarget:Element;

  connect():void {
    if (this.authorIdValue === this.currentUserId) {
      this.authorNameTarget.innerHTML = 'You';
    }
  }

  get currentUserId():number | undefined {
    const element = document.head.querySelector('meta[name=\'current_user\']');
    if (!element) {
      return undefined;
    }
    return Number(element.getAttribute('data-id'));
  }
}
