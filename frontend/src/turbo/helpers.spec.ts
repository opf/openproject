import * as Turbo from '@hotwired/turbo';
import { TurboHelpers } from './helpers';

describe('TurboHelpers.showProgressBar / hideProgressBar', () => {
  const progressBar = (Turbo.session.adapter as Turbo.BrowserAdapter).progressBar;
  /* eslint-disable @typescript-eslint/no-empty-function */
  let setValueSpy:ReturnType<typeof vi.spyOn>;
  let showSpy:ReturnType<typeof vi.spyOn>;
  let hideSpy:ReturnType<typeof vi.spyOn>;
  let savedDelay:number;

  beforeEach(() => {
    vi.useFakeTimers();
    setValueSpy = vi.spyOn(progressBar, 'setValue').mockImplementation(() => {});
    showSpy = vi.spyOn(progressBar, 'show').mockImplementation(() => {});
    hideSpy = vi.spyOn(progressBar, 'hide').mockImplementation(() => {});
    savedDelay = Turbo.config.drive.progressBarDelay;
    Turbo.config.drive.progressBarDelay = 200;
  });
  /* eslint-enable @typescript-eslint/no-empty-function */

  afterEach(() => {
    TurboHelpers.hideProgressBar();
    Turbo.config.drive.progressBarDelay = savedDelay;
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('sets value to 0 immediately', () => {
    TurboHelpers.showProgressBar();

    expect(setValueSpy).toHaveBeenCalledWith(0);
  });

  it('does not call show() before delay elapses', () => {
    TurboHelpers.showProgressBar();
    vi.advanceTimersByTime(199);

    expect(showSpy).not.toHaveBeenCalled();
  });

  it('calls show() after delay elapses', () => {
    TurboHelpers.showProgressBar();
    vi.advanceTimersByTime(200);

    expect(showSpy).toHaveBeenCalledOnce();
  });

  it('does not create multiple timeouts when called twice', () => {
    TurboHelpers.showProgressBar();
    TurboHelpers.showProgressBar();
    vi.advanceTimersByTime(200);

    expect(showSpy).toHaveBeenCalledOnce();
  });

  it('sets value to 1 and calls hide()', () => {
    TurboHelpers.hideProgressBar();

    expect(setValueSpy).toHaveBeenCalledWith(1);
    expect(hideSpy).toHaveBeenCalledOnce();
  });

  it('clears pending timeout so show() is never called', () => {
    TurboHelpers.showProgressBar();
    vi.advanceTimersByTime(100);
    TurboHelpers.hideProgressBar();
    vi.advanceTimersByTime(200);

    expect(showSpy).not.toHaveBeenCalled();
  });

  it('handles full show → delay → hide cycle', () => {
    TurboHelpers.showProgressBar();
    vi.advanceTimersByTime(200);

    expect(showSpy).toHaveBeenCalledOnce();

    TurboHelpers.hideProgressBar();

    expect(setValueSpy).toHaveBeenCalledWith(1);
    expect(hideSpy).toHaveBeenCalledOnce();
  });
});
