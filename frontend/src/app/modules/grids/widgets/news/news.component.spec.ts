
import { NewsDmService } from "core-app/modules/hal/dm-services/news-dm.service";
import { ComponentFixture, fakeAsync, TestBed, tick, async } from '@angular/core/testing';
import { WidgetNewsComponent } from './news.component';
import { DebugElement, NO_ERRORS_SCHEMA } from '@angular/core';
import { TimezoneService } from 'core-app/components/datetime/timezone.service';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { States } from 'core-app/components/states.service';
import { UserDmService } from 'core-app/modules/hal/dm-services/user-dm.service';
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { HttpClientModule } from "@angular/common/http";

fdescribe('shows news', () => {
  let app:WidgetNewsComponent;
  let fixture:ComponentFixture<WidgetNewsComponent>;


  let newsStub = {
    id: 1,
    title: 'Welcome to your demo project',
    author: {
      href: '/api/v3/users/1',
      name: 'Foo Bar'
    },
    summary: 'We are glad you joined. In this module you can communicate project news to your team members.\n',
    description: {
      format: 'markdown',
      raw: 'The actual news',
      html: '<p>The actual news</p>'
    },
    createdAt: '2020-03-26T10:42:14Z',
    updatedAt: '2020-03-26T10:42:14Z',
  };

  let newsDmStub = {
    list: (_params:any) => {
      return Promise.resolve({ elements: [newsStub] });
    }
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [
        WidgetNewsComponent],
      providers: [
        TimezoneService,
        { provide: ConfigurationService, useValue: {} },
        States,
        UserDmService,
        { provide: NewsDmService, useValue: newsDmStub },
        HalResourceService,
      ],
      imports: [HttpClientModule],
      schemas: [NO_ERRORS_SCHEMA]
    }).compileComponents();

    fixture = TestBed.createComponent(WidgetNewsComponent);
    app = fixture.debugElement.componentInstance;

  });

  it('should load news from the server', fakeAsync(() => {

    fixture.detectChanges();
    tick();
    expect(app.entries.length).toBe(1);

  }));

});