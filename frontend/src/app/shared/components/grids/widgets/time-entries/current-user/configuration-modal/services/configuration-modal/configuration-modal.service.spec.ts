import { TestBed } from '@angular/core/testing';
import { TimeEntriesCurrentUserConfigurationModalService } from './configuration-modal.service';

describe('TimeEntriesCurrentUserTimeEntriesCurrentUserConfigurationModalService', () => {
  let service:TimeEntriesCurrentUserConfigurationModalService;
  let daysCheckedValues:boolean[];

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        TimeEntriesCurrentUserConfigurationModalService,
      ],
    });

    service = TestBed.inject(TimeEntriesCurrentUserConfigurationModalService);
    daysCheckedValues = [true, true, true, true, true, true, false];
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should work with local offset 0', () => {
    const localWeekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const localOffset = 0;
    const orderedDaysData = service.getOrderedDaysData(daysCheckedValues, localWeekdays, localOffset);

    expect(orderedDaysData[0].weekDay).toBe('Sunday');
    expect(orderedDaysData[0].checked).toBe(false);
    expect(orderedDaysData[0].originalIndex).toBe(6);
    expect(orderedDaysData[6].weekDay).toBe('Saturday');
    expect(orderedDaysData[6].originalIndex).toBe(5);
    expect(orderedDaysData.filter((dayData) => dayData.checked).length).toBe(6);

    // Change the checked value of Monday to false
    orderedDaysData[1].checked = false;
    const getCheckedValuesInOriginalOrder = service.getCheckedValuesInOriginalOrder(orderedDaysData);
    const expectedResult = [false, true, true, true, true, true, false];

    expect(getCheckedValuesInOriginalOrder).toEqual(expectedResult);
  });

  it('should work with positive local offset (1)', () => {
    const localWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const localOffset = 1;
    const orderedDaysData = service.getOrderedDaysData(daysCheckedValues, localWeekdays, localOffset);

    expect(orderedDaysData[0].weekDay).toBe('Monday');
    expect(orderedDaysData[0].originalIndex).toBe(0);
    expect(orderedDaysData[6].weekDay).toBe('Sunday');
    expect(orderedDaysData[6].originalIndex).toBe(6);
    expect(orderedDaysData[6].checked).toBe(false);
    expect(orderedDaysData.filter((dayData) => dayData.checked).length).toBe(6);

    // Change the checked value of Monday to false
    orderedDaysData[0].checked = false;
    const getCheckedValuesInOriginalOrder = service.getCheckedValuesInOriginalOrder(orderedDaysData);
    const expectedResult = [false, true, true, true, true, true, false];

    expect(getCheckedValuesInOriginalOrder).toEqual(expectedResult);
  });

  it('should work with positive local offset (3)', () => {
    const localWeekdays = ['Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    const localOffset = 3;
    const orderedDaysData = service.getOrderedDaysData(daysCheckedValues, localWeekdays, localOffset);

    expect(orderedDaysData[0].weekDay).toBe('Wednesday');
    expect(orderedDaysData[0].originalIndex).toBe(2);
    expect(orderedDaysData[4].weekDay).toBe('Sunday');
    expect(orderedDaysData[4].originalIndex).toBe(6);
    expect(orderedDaysData[4].checked).toBe(false);
    expect(orderedDaysData.filter((dayData) => dayData.checked).length).toBe(6);

    // Change the checked value of Monday to false
    orderedDaysData[5].checked = false;
    const getCheckedValuesInOriginalOrder = service.getCheckedValuesInOriginalOrder(orderedDaysData);
    const expectedResult = [false, true, true, true, true, true, false];

    expect(getCheckedValuesInOriginalOrder).toEqual(expectedResult);
  });
});
