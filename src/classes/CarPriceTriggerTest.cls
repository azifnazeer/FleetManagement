@IsTest
private class CarPriceTriggerTest {

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

            List<Car__c> carList = TestDataUtils.createCars(carTypeList, 2);
            insert carList;

        }
    }

    @IsTest
    private static void testSingleCarPriceAvailabilityAtATime() {

        List<Price__c> priceList = new List<Price__c>();
        List<CarPrice__c> carPriceList = new List<CarPrice__c>();
        Map<Id, Price__c> priceByCarTypeIdMap = new Map<Id, Price__c>();

        Boolean hasCarsWithWrongActiveCarPrices = false;

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);


        System.runAs(testUser) {

            List<Car__c> carList = [SELECT Id, CarType__c FROM Car__c];
            List<CarType__c> carTypeList = [SELECT Id FROM CarType__c];

            Test.startTest();

            for(CarType__c carType : carTypeList) {

                //Insert new prices for the same car type with a different monthly amount
                priceList.add(new Price__c(CarType__c = carType.Id, MonthlyAmount__c = 469.00, StartDate__c = Date.today(), IsActive__c = true));
                insert priceList;
            }

            priceByCarTypeIdMap = getPriceMapByCarTypeId(priceList);

            for(Car__c car : carList) {

                //Insert new car prices for the cars with the newly created prices
                carPriceList.add(new CarPrice__c(Price__c = priceByCarTypeIdMap.get(car.CarType__c).Id, Car__c = car.Id, IsActive__c = true));
                upsert carPriceList;
            }

            Test.stopTest();

            List<CarPrice__c> carPriceTypeListAfterNewPrices = [SELECT Id, Price__r.MonthlyAmount__c, IsActive__c FROM CarPrice__c];


            //Assert that there are no active car prices for Cars with old monthly amount
            for (CarPrice__c carPrice : carPriceTypeListAfterNewPrices) {
                if (carPrice.IsActive__c && !(carPrice.Price__r.MonthlyAmount__c == 469.00)) {
                    hasCarsWithWrongActiveCarPrices = true;
                }
            }

            System.assert(!hasCarsWithWrongActiveCarPrices);

        }

    }

    private static Map<Id, Price__c> getPriceMapByCarTypeId(List<Price__c> priceList) {
        Map<Id, Price__c> priceByCarTypeIdMap = new Map<Id, Price__c>();

        for(Price__c price : priceList) {
            if(priceByCarTypeIdMap.get(price.CarType__c) == null) {
                priceByCarTypeIdMap.put(price.CarType__c, price);
            }
        }

        return priceByCarTypeIdMap;
    }

}