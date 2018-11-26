@IsTest
private class SubscriptionTriggerTest {

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

            List<Subscription__c> subscriptionList = TestDataUtils.createSubscriptions(carList, accountList);
            insert subscriptionList;
        }

    }

    @IsTest
    private static void testPreventionOfSubscriptionCreationForNonAvailableCars() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            List<Car__c> nonAvailableCarList = [SELECT Id, CarType__c FROM Car__c WHERE IsAvailable__c = false];
            List<Account> accountList = [SELECT Id FROM Account];

            List<Subscription__c> subscriptionList = TestDataUtils.createSubscriptions(nonAvailableCarList, accountList);


            Test.startTest();

            try{
                insert subscriptionList;
            } catch(Exception e) {
                Boolean expectedExceptionThrown =  e.getMessage().contains('There is no Car available of this Car Type. Hence cannot create this subscription. Please choose a different Car Type') ? true : false;

                //Assert that exception has been thrown
                System.AssertEquals(expectedExceptionThrown, true);
            }

            Test.stopTest();

        }

    }

    @IsTest
    private static void testCarAssignmentForContractedSubscriptions() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            Subscription__c oldContractedSubscription = [SELECT Id, Status__c, Car__c, CarType__c FROM Subscription__c WHERE Status__c = 'Contracted' LIMIT 1];
            Account account = [SELECT Id FROM Account LIMIT 1];

            Id availableCarId = oldContractedSubscription.Car__c;


            Test.startTest();

            //Terminate the subscription and add an enddate, so that the Car__c associated with this is free again
            oldContractedSubscription.EndDate__c = Date.today();
            oldContractedSubscription.Status__c = 'Terminated';

            update oldContractedSubscription;

            //Insert new subscription
            Subscription__c newSubscription = new Subscription__c(Account__c = account.Id, StartDate__c = Date.today().addYears(-2), EndDate__c = Date.today().addYears(4), CarType__c = oldContractedSubscription.CarType__c, Status__c = 'Contracted');
            insert newSubscription;

            Test.stopTest();

            Subscription__c subscriptionAfterInsert = [SELECT Id, Car__c FROM Subscription__c WHERE Id = :newSubscription.Id LIMIT 1];

            //Assert that the previously freed car has been reassigned to the newly created subscription
            System.assertEquals(availableCarId, subscriptionAfterInsert.Car__c);

        }

    }

    @IsTest
    private static void testUnblockingOfCarsForTerminatedSubscriptions() {

        User testUser = TestDataUtils.getTestUser('FleetManager', 'FleetManager', 2);

        System.runAs(testUser) {

            Subscription__c contractedSubscription = [SELECT Id, Status__c, Car__c FROM Subscription__c WHERE Status__c = 'Contracted' LIMIT 1];


            Test.startTest();

            //Terminate the subscription and add an enddate
            contractedSubscription.EndDate__c = Date.today();
            contractedSubscription.Status__c = 'Terminated';

            update contractedSubscription;

            Test.stopTest();

            Car__c car = [SELECT Id, IsAvailable__c FROM Car__c WHERE Id = :contractedSubscription.Car__c LIMIT 1];

            //Assert that the car is available again
            System.assert(car.IsAvailable__c);

        }

    }

}