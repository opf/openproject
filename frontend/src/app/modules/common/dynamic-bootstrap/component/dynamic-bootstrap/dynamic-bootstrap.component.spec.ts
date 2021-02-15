import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DynamicBootstrapComponent } from './dynamic-bootstrap.component';

fdescribe('DynamicBootstrapComponent', () => {
  let component: DynamicBootstrapComponent;
  let fixture: ComponentFixture<DynamicBootstrapComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ DynamicBootstrapComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DynamicBootstrapComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
