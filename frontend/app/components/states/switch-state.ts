import {InputState, derive, input, State, IfThen} from 'reactivestates';
import {debugLog} from "../../helpers/debug_output";

export class SwitchState<StateName> {

  private readonly contextSwitch$: InputState<StateName> = input<StateName>();

  public transition(context: StateName) {
    if (this.validTransition(context)) {
      debugLog(`Switching table context to ${context}`);
      this.contextSwitch$.putValue(context);
    }
  }

  public validTransition(to: StateName) {
    return (this.contextSwitch$.value !== to);
  }

  public get current():StateName|undefined {
    return this.contextSwitch$.value;
  }

  public reset(reason?: string) {
    debugLog('Resetting table context.');
    this.contextSwitch$.clear(reason);
  }

  public doAndTransition(context: StateName, callback:() => PromiseLike<any>) {
    this.reset('Clearing before transitioning to ' + context);
    const promise = callback();
    promise.then(() => this.transition(context));
  }

  public fireOnTransition<T>(cb: State<T>, ...context: StateName[]): State<T> {
    return IfThen(this.contextSwitch$, s => context.indexOf(s) > -1, cb);
  }

  public fireOnStateChange<T>(state: State<T>, ...context: StateName[]): State<T> {
    return derive(state, $ => $
      .filter(() => this.contextSwitch$.hasValue() && context.indexOf(this.contextSwitch$.value!) > -1))
  }
}
