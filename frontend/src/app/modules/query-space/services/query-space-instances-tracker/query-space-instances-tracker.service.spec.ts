import { TestBed } from '@angular/core/testing';

import { QuerySpaceInstancesTrackerService } from './query-space-instances-tracker.service';

describe('QuerySpaceInstancesTrackerService', () => {
  let service: QuerySpaceInstancesTrackerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(QuerySpaceInstancesTrackerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
