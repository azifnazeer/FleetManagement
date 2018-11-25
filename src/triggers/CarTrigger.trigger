trigger CarTrigger on Car__c (after insert) {

    if(Trigger.isAfter && Trigger.isInsert) {
        //Choose the right active price for car price creation
        createCarPriceForNewCars(Trigger.new);
    }

    /**
    *  Method to create Car Price for each newly created Car
    */
    private void createCarPriceForNewCars(List<Car__c> currentCarList) {

        Map<Id, Price__c> pricesByCarTypeIdMap = getPricesByCarTypeIdMap(currentCarList);
        List<CarPrice__c> carPriceToBeCreated = new List<CarPrice__c>();

        try{

            if(!pricesByCarTypeIdMap.isEmpty()) {
                for(Car__c currentCar : currentCarList) {

                    CarPrice__c carPrice = new CarPrice__c();
                    carPrice.Car__c = currentCar.Id;
                    carPrice.Price__c = pricesByCarTypeIdMap.get(currentCar.CarType__c).Id;
                    carPrice.IsActive__c = true;

                    carPriceToBeCreated.add(carPrice);

                }

                if(!carPriceToBeCreated.isEmpty()) {
                    insert carPriceToBeCreated;
                }
            }
        }catch(Exception e) {
            System.debug('Exception Caught:' + e);
        }

    }

    /**
    *  Method to return a map of prices, with Car Type Id as the key
    */
    private Map<Id, Price__c> getPricesByCarTypeIdMap(List<Car__c> currentCarList) {

        Map<Id, Price__c> pricesByCarTypeIdMap = new Map<Id, Price__c>();

        Set<Id> carTypeIdSet = new Set<Id>();

        for(Car__c currentCar : currentCarList) {
            carTypeIdSet.add(currentCar.CarType__c);
        }

        if(!carTypeIdSet.isEmpty()) {
            List<Price__c> priceList = [SELECT Id, CarType__c FROM Price__c WHERE CarType__c IN :carTypeIdSet AND IsActive__c = true];

            for(Price__c price : priceList) {
                pricesByCarTypeIdMap.put(price.CarType__c, price);
            }
        }

        return pricesByCarTypeIdMap;

    }

}