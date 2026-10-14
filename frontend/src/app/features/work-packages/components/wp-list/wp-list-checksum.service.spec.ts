import { TestBed } from '@angular/core/testing';
import * as Turbo from '@hotwired/turbo';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { NavigationService } from 'core-app/core/navigation/navigation.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackagesListChecksumService } from './wp-list-checksum.service';

describe('WorkPackagesListChecksumService', () => {
  let service:WorkPackagesListChecksumService;
  let pushSpy:jasmine.Spy;

  const pagination = { perPage: 20, page: 1 } as never;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        WorkPackagesListChecksumService,
        UrlParamsService,
        { provide: NavigationService, useValue: { urlChanged$: { pipe: () => ({}) } } },
        {
          provide: UrlParamsHelperService,
          useValue: { encodeQueryJsonParams: () => '{"f":"new"}' },
        },
      ],
    });

    service = TestBed.inject(WorkPackagesListChecksumService);
    pushSpy = spyOn(Turbo.session.history, 'push');
    service.set('1', '{"f":"old"}');
  });

  it('pushes the URL to history by default', () => {
    void service.updateIfDifferent({ id: '1' } as never, pagination);

    expect(pushSpy).toHaveBeenCalled();
  });

  it('does not touch the URL or history when urlSyncDisabled is set', () => {
    service.urlSyncDisabled = true;
    const visible:(string|null)[] = [];
    service.visibleChecksum$.subscribe((v) => visible.push(v));

    void service.updateIfDifferent({ id: '1' } as never, pagination);
    service.update({ id: '1' } as never, pagination);

    expect(pushSpy).not.toHaveBeenCalled();
    expect(service.consumeSelfInitiatedUrlChangeFlag()).toBe(false);
    expect(visible.length).toBeGreaterThan(0);
  });
});
