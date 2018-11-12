import {derive, IfThen, input, InputState, State} from 'reactivestates';
import {filter} from 'rxjs/operators';
import {debugLog} from '../../helpers/debug_output';

export class SwitchState<StateName> {

  private readonly contextSwitch$:InputState<StateName> = input<StateName>();

  public transition(context:StateName) {
    if (this.validTransition(context)) {
      this.contextSwitch$.putValue(context);
    }
  }

  public validTransition(to:StateName) {
    return (this.contextSwitch$.value !== to);
  }

  public get current():StateName | undefined {
    return this.contextSwitch$.value;
  }

  public reset(reason?:string) {
    this.contextSwitch$.clear(reason);
  }

  public doAndTransition(context:StateName, callback:() => PromiseLike<any>):PromiseLike<void> {
    this.reset('Clearing before transitioning to ' + context);
    const promise = callback();
    return promise.then(() => this.transition(context));
  }

  public fireOnTransition<T>(cb:State<T>, ...context:StateName[]):State<T> {
    return IfThen(this.contextSwitch$, s => context.indexOf(s) > -1, cb);
  }

  public fireOnStateChange<T>(state:State<T>, ...context:StateName[]):State<T> {
    return derive(state, $ => $
      .pipe(
        filter(() => this.contextSwitch$.hasValue() && context.indexOf(this.contextSwitch$.value!) > -1))
    );
  }
}
