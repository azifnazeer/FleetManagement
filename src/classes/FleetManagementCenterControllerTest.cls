@IsTest
public with sharing class FleetManagementCenterControllerTest {

    @TestSetup
    private static void createTestData() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 1);

        System.runAs(testUser) {

            List<Account> accountList = TestDataUtils.createAccounts(20);
            insert accountList;

            List<CarManufacturer__c> carManufacturerList = TestDataUtils.createCarManufacturers(5);
            insert carManufacturerList;

            List<CarType__c> carTypeList = TestDataUtils.createCarTypes(carManufacturerList, 4);
            insert  carTypeList;

            List<Price__c> priceList = TestDataUtils.createPrices(carTypeList);
            insert priceList;

            List<Car__c> carList = TestDataUtils.createCars(carTypeList, 3);
            insert carList;

            List<Subscription__c> subscriptionList = TestDataUtils.createSubscriptions(carList, accountList);
            insert subscriptionList;

        }

    }

    @IsTest
    private static void testGetCarTypeWrapperList() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            Test.stopTest();

            //Assert carTypeWrapperList member variable is not null
            System.assertNotEquals(null, fleetManagementCenterController.carTypeWrapperList);

            //Assert carTypeWrapperList has 10 Car Types
            System.assertEquals(10, fleetManagementCenterController.carTypeWrapperList.size());

            //Obtain a single car wrapper record for further assertions
            FleetManagementUtils.CarTypeWrapper carTypeWrapper = fleetManagementCenterController.carTypeWrapperList.get(0);

            //Assert the wrapper data
            System.assertEquals(3, carTypeWrapper.numberOfCarsOwned);
            System.assertEquals(3, carTypeWrapper.numberOfCarsOnRoad);
            System.assertEquals(3, carTypeWrapper.carList.size());
            System.assertEquals(false, carTypeWrapper.selected);

        }

    }

    @IsTest
    private static void testSelectedCarTypeDetailsWrapperList() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            //Select 3 Car Types from the current Car Types
            fleetManagementCenterController.carTypeWrapperList.get(0).selected = true;
            fleetManagementCenterController.carTypeWrapperList.get(1).selected = true;
            fleetManagementCenterController.carTypeWrapperList.get(2).selected = true;

            //Simulating the click of Show Selected Car Types Button
            fleetManagementCenterController.updateSelectedCarTypeDetailsWrapperList();

            //Fetch the selected car type details wrapper
            List<FleetManagementUtils.CarTypeDetailsWrapper> selectedCarTypeDetailsWrapperList = fleetManagementCenterController.getSelectedCarTypeDetailsWrapperList();

            Test.stopTest();

            //Assert selectedCarTypeDetailsWrapperList member variable is not null
            System.assertNotEquals(null, selectedCarTypeDetailsWrapperList);

            //Assert selectedCarTypeDetailsWrapperList has 3 Car Detail Types
            System.assertEquals(3, fleetManagementCenterController.selectedCarTypeDetailsWrapperList.size());

            //Obtain a single car wrapper record for further assertions
            FleetManagementUtils.CarTypeDetailsWrapper carTypeDetailsWrapper = fleetManagementCenterController.selectedCarTypeDetailsWrapperList.get(0);

            //Assert the wrapper data
            System.assertEquals(0, carTypeDetailsWrapper.numberOfAvailableCars);
            System.assertEquals(Date.today().addYears(-2).format(), carTypeDetailsWrapper.firstSubscriptionDate);

        }

    }

    @IsTest
    private static void testFilteringByManufacturer() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            CarManufacturer__c selectedCarManufacturer = [SELECT Id FROM CarManufacturer__c WHERE Name = 'testCarManufacturer1' LIMIT 1];

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            //Apply one of the brand name as the filter
            List<SelectOption> manufacturerSelectOptions = fleetManagementCenterController.getManufacturerSelectOptions();
            fleetManagementCenterController.selectedManufacturer = selectedCarManufacturer.Id;

            //Simulating the filter action
            fleetManagementCenterController.resetPaginationParametersAndCarTypeSelections();

            //Fetching the car type wrapper again
            carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            Test.stopTest();

            //Assert select option has all 5 Manufacturers plus an all option, hence total 6
            System.assertEquals(6, manufacturerSelectOptions.size());

            //Assert carTypeWrapperList member variable is not null
            System.assertNotEquals(null, fleetManagementCenterController.carTypeWrapperList);

            //Assert carTypeWrapperList has just two Car Types from selected Brand
            System.assertEquals(4, fleetManagementCenterController.carTypeWrapperList.size());

        }

    }

    @IsTest
    private static void testInfoMessageForZeroSelections() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            //Simulating the click of Show Selected Car Types Button
            fleetManagementCenterController.updateSelectedCarTypeDetailsWrapperList();

            Test.stopTest();

            //Assert selectedCarTypeDetailsWrapperList is empty
            System.assert(fleetManagementCenterController.selectedCarTypeDetailsWrapperList.isEmpty());

            //Assert one info message is present
            System.assertEquals(1, ApexPages.getMessages().size());

        }

    }

    @IsTest
    private static void testPagination() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            //Assert hasPrevious pagination parameter
            System.assert(fleetManagementCenterController.getHasPrevious());

            //Simulate the move to next page
            fleetManagementCenterController.next();

            //Assert pagination parameters
            System.assertEquals(2, fleetManagementCenterController.getTotalPages());
            System.assertEquals(2, fleetManagementCenterController.getPageNumber());
            System.assert(fleetManagementCenterController.getHasNext());

            //Simulate the move to next page
            fleetManagementCenterController.next();

            //Simulate the move to first page
            fleetManagementCenterController.first();

            //Simulate the move to next page again
            fleetManagementCenterController.next();

            //Assert that the offset parameter is set to 10, as per the pagination size
            System.assertEquals(10, fleetManagementCenterController.currentListOffset);

            //Simulate the move to previous page
            fleetManagementCenterController.previous();

            //Simulate the move to last page
            fleetManagementCenterController.last();

            //Reset the pagination parameters now
            fleetManagementCenterController.resetPaginationParametersAndCarTypeSelections();

            Test.stopTest();

            //Assert that the offset parameter is reset to 0
            System.assertEquals(0, fleetManagementCenterController.currentListOffset);

        }

    }

    @IsTest
    private static void testSorting() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            //Simulate the click for sorting simultaneously and finalise on Number Of Cars Owned
            fleetManagementCenterController.sortByNumberOfCarsOnRoad();
            fleetManagementCenterController.orderByAscDesc = 'Asc';

            fleetManagementCenterController.sortByAverageRevenuePerKmSort();
            fleetManagementCenterController.orderByAscDesc = 'Asc';

            fleetManagementCenterController.sortByNumberOfCarsOwned();
            fleetManagementCenterController.orderByAscDesc = 'Desc';

            Test.stopTest();

            //Assert the sorting parameters
            System.assert(fleetManagementCenterController.numberOfCarsOwnedSort);
            System.assert(!fleetManagementCenterController.numberOfCarsOnRoadSort);
            System.assert(!fleetManagementCenterController.averageRevenuePerKmSort);

            System.assertEquals('NumberOfCarsOwned__c', fleetManagementCenterController.orderBy);

        }

    }

    @IsTest
    private static void testCancelAction() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            PageReference fleetManagementCenter = Page.FleetManagementCenter;
            Test.setCurrentPage(fleetManagementCenter);

            Test.startTest();

            FleetManagementCenterController fleetManagementCenterController = new FleetManagementCenterController();
            List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = fleetManagementCenterController.getCarTypeWrapperList();

            PageReference homePageReference = fleetManagementCenterController.cancel();

            Test.stopTest();

            //Assert that the cancel action has returned home page reference
            System.assertNotEquals(null, homePageReference);

        }

    }

}