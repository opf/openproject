import { TestBed } from '@angular/core/testing';

import { QuerySpaceService } from './query-space.service';

describe('QuerySpaceService', () => {
  let service: QuerySpaceService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(QuerySpaceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
