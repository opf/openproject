import { LiveController } from '@camertron/live-component';

export default class PageHeaderLiveController extends LiveController {
  static targets = ['titleInput'];

  declare readonly titleInputTarget:HTMLInputElement;
  declare readonly hasTitleInputTarget:boolean;

  edit(event:Event):void {
    event.preventDefault();
    void this.render((component) => { component.props.state = 'edit'; });
  }

  cancel(event:Event):void {
    event.preventDefault();
    void this.render((component) => { component.props.state = 'show'; });
  }

  after_update():void {
    if (this.hasTitleInputTarget) {
      this.titleInputTarget.focus();
      this.titleInputTarget.select();
    }
  }
}
