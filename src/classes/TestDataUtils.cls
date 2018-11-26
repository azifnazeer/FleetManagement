@IsTest
public with sharing class TestDataUtils {

    public static User testUser;

    public static User getTestUser(String profileName, String roleName, Integer index) {

        if(testUser == null) {
            testUser = createTestUser(profileName, roleName, index);
        }

        return testUser;

    }

    public static User createTestUser(String profileName, String roleName, Integer index) {

        User testUser = new User();

        testUser.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :profileName].Id;
        testUser.FirstName = 'Test' + index;
        testUser.LastName = 'User' + index;
        testUser.Alias = 'testusr' + index;
        testUser.Email = 'test@clunouser.com' + index;
        testUser.Username = 'test@clunouser.com' + index;
        testUser.CommunityNickname = 'testusr' + index;
        testUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = :roleName].Id;
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LanguageLocaleKey = 'de';
        testUser.LocaleSidKey = 'de_DE';
        testUser.TimeZoneSidKey = 'Europe/Berlin';

        return testUser;

    }


    public static List<Account> createAccounts(Integer numberOfAccountsToBeCreated) {

        List<Account> accountList = new List<Account>();

        for (Integer i = 0; i < numberOfAccountsToBeCreated; i++) {

            String accName = 'testAccount' + (i * (i + i)) ;

            accountList.add(new Account(Name = accName));

        }

        return accountList;

    }


    public static List<CarManufacturer__c> createCarManufacturers(Integer numberOfCarManufacturersToBeCreated) {

        List<CarManufacturer__c> carManufacturerList = new List<CarManufacturer__c>();

        for (Integer i = 0; i < numberOfCarManufacturersToBeCreated; i++) {

            String carManufacturer = 'testCarManufacturer' + i;

            carManufacturerList.add(new CarManufacturer__c(Name = carManufacturer));

        }

        return carManufacturerList;

    }

    public static List<CarType__c> createCarTypes(List<CarManufacturer__c> carManufacturerList, Integer numberOfCarTypesPerManufacturerToBeCreated) {

        List<CarType__c> carTypeList = new List<CarType__c>();

        for(CarManufacturer__c carManufacturer : carManufacturerList) {
            for(Integer i = 0; i < numberOfCarTypesPerManufacturerToBeCreated ; i++) {

                String carTypeName = 'testCarTypeName' + i;

                carTypeList.add(new CarType__c(Name = carManufacturer.Name, Manufacturer__c = carManufacturer.Id));

            }
        }

        return carTypeList;

    }

    public static List<Price__c> createPrices(List<CarType__c> carTypeList) {

        List<Price__c> priceList = new List<Price__c>();

        for(CarType__c carType : carTypeList) {

            priceList.add(new Price__c(CarType__c = carType.Id, MonthlyAmount__c = 369.00, StartDate__c = Date.today().addYears(-3), IsActive__c = true));

        }

        return priceList;

    }

    public static List<Car__c> createCars(List<CarType__c> carTypeList, Integer numberOfCarsPerCarTypeToBeCreated) {

        List<Car__c> carList = new List<Car__c>();

        for(CarType__c carType : carTypeList) {

            for(Integer i = 0 ; i < numberOfCarsPerCarTypeToBeCreated ; i++) {
                String carName = 'testCarName' + i;

                carList.add(new Car__c(CarType__c = carType.Id, KilometersDriven__c = 10000 + i, IsAvailable__c = true ));
            }

        }

        return carList;

    }

    /*
    public static List<CarPrice__c> createCarPrices(List<Car__c> carList, List<Price__c> priceList) {

        List<CarPrice__c> carPricesList = new List<CarPrice__c>();

        for(Car__c car : carList) {

            for(Price__c price : priceList) {

                if(price.CarType__c == car.CarType__c) {
                    carPricesList.add(new CarPrice__c(Price__c = price.Id, Car__c = car.Id));
                }
            }

        }

        return carPricesList;

    }
    */

    public static List<Subscription__c> createSubscriptions(List<Car__c> carList, List<Account> accountList) {

        List<Subscription__c> subscriptionList = new List<Subscription__c>();

        Integer counter = 0;
        Integer accountListSize = accountList.size();

        for(Car__c car : carList) {

            if(counter < accountListSize) {
                subscriptionList.add(new Subscription__c(Account__c = accountList.get(counter).Id, StartDate__c = Date.today().addYears(-2), EndDate__c = Date.today().addYears(4), CarType__c = car.CarType__c, Status__c = 'Contracted'));
            } else {
                counter = 0;
            }

            counter ++;

        }

        return subscriptionList;

    }


}