@IsTest
private class CarTriggerTest {

    @TestSetup
    private static void createTestData() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 1);

        System.runAs(testUser) {

            List<Account> accountList = TestDataUtils.createAccounts(2);
            insert accountList;

            List<CarManufacturer__c> carManufacturerList = TestDataUtils.createCarManufacturers(1);
            insert carManufacturerList;

            List<CarType__c> carTypeList = TestDataUtils.createCarTypes(carManufacturerList, 1);
            insert carTypeList;

            List<Price__c> priceList = TestDataUtils.createPrices(carTypeList);
            insert priceList;

        }

    }

    @IsTest
    private static void testCarPriceCreationForNewCars() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);


        System.runAs(testUser) {

            Boolean hasCarPricesCreatedForAllCars = true;
            List<CarType__c> carTypeList = [SELECT Id FROM CarType__c];
            List<Car__c> carList = TestDataUtils.createCars(carTypeList, 2);

            Test.startTest();

            //Insert Cars now
            insert carList;

            Test.stopTest();

            List<Car__c> carListAfterInsert = [SELECT Id, (SELECT Id FROM CarPrices__r) FROM Car__c];

            for(Car__c car : carListAfterInsert) {
                if(car.CarPrices__r.size() == 0) {
                    hasCarPricesCreatedForAllCars = false;
                }
            }

            //Assert that all Cars have Car Prices
            System.assert(hasCarPricesCreatedForAllCars);

        }

    }

}