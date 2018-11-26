@IsTest
private class PriceTriggerTest {

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
    private static void testSinglePriceAvailabilityAtATime() {

        List<Price__c> priceList = new List<Price__c>();
        Boolean hasWrongActivePrices = false;
        Boolean hasCarTypesWithWrongActivePrices = false;

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);


        System.runAs(testUser) {

            List<CarType__c> carTypeList = [SELECT Id FROM CarType__c];

            Test.startTest();

            for(CarType__c carType : carTypeList) {

                //Insert new prices for the same car types with a different monthly amount
                priceList.add(new Price__c(CarType__c = carType.Id, MonthlyAmount__c = 469.00, StartDate__c = Date.today(), IsActive__c = true));
                insert priceList;
            }

            Test.stopTest();

            List<Price__c> completePriceList = [SELECT Id, MonthlyAmount__c, IsActive__c FROM Price__c WHERE CarType__c IN :carTypeList];
            List<CarType__c> carTypeListAfterNewPrices = [SELECT Id, (SELECT Id, MonthlyAmount__c FROM Prices__r WHERE IsActive__c = true) FROM CarType__c];

            //Assert that there are no active prices with old monthly amount
            for(Price__c price : completePriceList) {
                if(price.IsActive__c && price.MonthlyAmount__c != 469.00) {
                    hasWrongActivePrices = true;
                }
            }

            System.assert(!hasWrongActivePrices);

            //Assert that there are no active prices for Car Types with old monthly amount
            for(CarType__c carType : carTypeListAfterNewPrices) {
                for(Price__c price : carType.Prices__r) {
                    if(!(price.MonthlyAmount__c == 469.00)) {
                        hasCarTypesWithWrongActivePrices = true;
                    }
                }
            }

            System.assert(!hasWrongActivePrices);

        }

    }

}