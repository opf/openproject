import { TestBed } from '@angular/core/testing';
import { MyNotificationsPageService } from "core-app/features/my-account/my-notifications-page/my-notifications-page.service";


describe('MyNotificationsPageService', () => {
  let service: MyNotificationsPageService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MyNotificationsPageService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
