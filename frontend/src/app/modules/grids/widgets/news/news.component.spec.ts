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
import { By } from '@angular/platform-browser';

describe('shows news', () => {
  let app:WidgetNewsComponent;
  let fixture:ComponentFixture<WidgetNewsComponent>;
  let element:DebugElement;

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

  let newsDmServiceStub = {
    list: (_params:any) => {
      return Promise.resolve({ elements: [newsStub] });
    }
  };

  let configurationServiceStub = {
    isTimezoneSet: () => false,
    dateFormatPresent: () => false,
    timeFormatPresent: () => false
  };
  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [
        WidgetNewsComponent],
      providers: [
        TimezoneService,
        { provide: ConfigurationService, useValue: configurationServiceStub },
        States,
        UserDmService,
        { provide: NewsDmService, useValue: newsDmServiceStub },
        HalResourceService,
      ],
      imports: [HttpClientModule],
      schemas: [NO_ERRORS_SCHEMA]
    }).compileComponents();

    fixture = TestBed.createComponent(WidgetNewsComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.debugElement;
  });

  it('should load news from the server', fakeAsync(() => {
    fixture.detectChanges();
    tick();
    expect(app.entries.length).toBe(1);
  }));


  it('should render the componenet successfully to show the news', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      let newsItem = document.querySelector('li');
      expect(document.contains(newsItem)).toBeTruthy();
    });
  }));

  it('should Not add the no-results component into DOM', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      let newsItem = document.querySelector('no-results');
      expect(document.contains(newsItem)).not.toBeTruthy();
    });
  }));

  it('should add the widget-header component into DOM', async(() => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      let newsItem = document.querySelector('widget-header');
      expect(document.contains(newsItem)).toBeTruthy();
    });
  }));

  it('should show summary of news', async(() => {
    fixture.detectChanges();

    fixture.whenStable().then(() => {
      let newsItem:HTMLElement = element.query(By.css('.widget-box--additional-info')).nativeElement;
      expect(newsItem.innerText).toContain('We are glad you joined.');

    });
  }));

  it('should Not add the user-avatar component into DOM', async(() => {
    fixture.detectChanges();

    fixture.whenStable().then(() => {
      let newsItem = document.querySelector('user-avatar');
      expect(document.contains(newsItem)).toBeTruthy();

    });
  }));
});