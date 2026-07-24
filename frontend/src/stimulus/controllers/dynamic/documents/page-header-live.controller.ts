import { LiveController } from '@camertron/live-component';

export default class PageHeaderLiveController extends LiveController {
  static targets = ['titleInput'];

  declare readonly titleInputTarget:HTMLInputElement;
  declare readonly hasTitleInputTarget:boolean;

  edit(event:Event):void {
    event.preventDefault();
    this.render((component) => { component.props.state = 'edit'; }).catch(() => undefined);
  }

  cancel(event:Event):void {
    event.preventDefault();
    this.render((component) => { component.props.state = 'show'; }).catch(() => undefined);
  }

  save(event:Event):void {
    event.preventDefault();
    const title = this.titleInputTarget.value;
    this.render((component) => {
      component.call('update_title', { title });
    }).catch(() => undefined);
  }

  after_update():void {
    if (this.hasTitleInputTarget) {
      this.titleInputTarget.focus();
      this.titleInputTarget.select();
    }

    const url = new URL(window.location.href);
    if (url.searchParams.has('state')) {
      url.searchParams.delete('state');
      window.history.replaceState({}, document.title, url.toString());
    }
  }
}
