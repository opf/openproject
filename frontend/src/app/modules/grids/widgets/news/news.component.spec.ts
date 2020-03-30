import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import { WidgetNewsComponent } from './news.component';
import { By } from '@angular/platform-browser';
import { DebugElement, NO_ERRORS_SCHEMA, Injector } from '@angular/core';
//import { Promise } from 'es6-shim';
import {NewsDmService} from "core-app/modules/hal/dm-services/news-dm.service";
import { HttpClientModule } from '@angular/common/http';
import { TimezoneService } from 'core-app/components/datetime/timezone.service';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { ConfigurationDmService } from 'core-app/modules/hal/dm-services/configuration-dm.service';
import { UserCacheService } from 'core-app/components/user/user-cache.service';
import { States } from 'core-app/components/states.service';
import { UserDmService } from 'core-app/modules/hal/dm-services/user-dm.service';
import { CollectionResource } from 'core-app/modules/hal/resources/collection-resource';
import { NewsResource } from 'core-app/modules/hal/resources/news-resource';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { any } from '@uirouter/core';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';



fdescribe('shows news', () => {
    let app:WidgetNewsComponent;
    let fixture:ComponentFixture<WidgetNewsComponent>;
    let element:DebugElement;

beforeEach(() => {

    TestBed.configureTestingModule({
      declarations: [
        WidgetNewsComponent
      ],
      providers: [TimezoneService,ConfigurationService,ConfigurationDmService,
        UserCacheService,States,UserDmService,NewsDmService,Injector,HalResourceService
      ],
      imports:[HttpClientModule],
      schemas:[NO_ERRORS_SCHEMA]
    }).compileComponents();


    fixture = TestBed.createComponent(WidgetNewsComponent);
    app = fixture.debugElement.componentInstance;
    
  });

it('should load news from the server',()=>{
  
  
   let data=  [
    {
      _type: 'News',
      id: 1,
      title: 'Welcome to your demo project',
      summary: 'We are glad you joined. In this module you can communicate project news to your team members.\n',
      description: {
        format: 'markdown',
        raw: 'The actual news',
        html: '<p>The actual news</p>'
      },
      createdAt: '2020-03-26T10:42:14Z',
      updatedAt: '2020-03-26T10:42:14Z',
      _links: {
        self: {
          href: '/api/v3/news/1',
          title: 'Welcome to your demo project'
        },
        project: {
          href: '/api/v3/projects/1',
          title: 'Demo project'
        },
        author: {
          href: null
        }
      
    }}
  ];
  

    app.setupNews(data);


    fixture.detectChanges();

  

    expect(app.entries.length).toBe(1);
});


});