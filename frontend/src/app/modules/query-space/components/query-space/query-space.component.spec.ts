import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { QuerySpaceComponent } from './query-space.component';

describe('QuerySpaceComponent', () => {
  let component: QuerySpaceComponent;
  let fixture: ComponentFixture<QuerySpaceComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ QuerySpaceComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(QuerySpaceComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
