trigger SubscriptionTrigger on Subscription__c (before insert, after insert, after update) {

    private static Map<Id, CarType__c> carTypeByIdMap;

    if (Trigger.isBefore && Trigger.isInsert) {
        preventSubscriptionCreationForNonAvailableCars(Trigger.new);
        assignAndBlockCarForContractedSubscriptions(Trigger.new);
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        unblockCarsForTerminatedSubscriptions(Trigger.new);
    }

    private void preventSubscriptionCreationForNonAvailableCars(List<Subscription__c> currentSubscriptionList) {

        carTypeByIdMap = getCarTypeByIdMap(currentSubscriptionList);

        for (Subscription__c currentSubscription : currentSubscriptionList) {

            if (carTypeByIdMap.get(currentSubscription.CarType__c).NumberOfAvailableCars__c <= 0) {
                for (Subscription__c subscriptionWithOrWithoutAvailableCar : Trigger.new) {

                    //Add error for all those subscription which has the same Car Type with <= 0 available Cars
                    if (currentSubscription.CarType__c == subscriptionWithOrWithoutAvailableCar.CarType__c) {
                        subscriptionWithOrWithoutAvailableCar.addError('There is no Car available of this Car Type. Hence cannot create this subscription. Please choose a different Car Type');
                    }

                }
            }

        }

    }

    private void assignAndBlockCarForContractedSubscriptions(List<Subscription__c> currentSubscriptionList) {

        Set<Id> availableCarTypeOfContractedSubscriptionsSet = new Set<Id>();
        Map<Id, List<Car__c>> availableCarsByCarTypeIdMap = new Map<Id, List<Car__c>>();
        List<Subscription__c> subscriptionWithAvailableCarList = new List<Subscription__c>();
        List<Car__c> carsToBeUpdatedWithAvailability = new List<Car__c>();

        carTypeByIdMap = getCarTypeByIdMap(currentSubscriptionList);

        for (Subscription__c currentSubscription : currentSubscriptionList) {

            //TODO: Optimise further later for bulk loads, regarding the availability of the same car if it occurs more than one time.
            if (carTypeByIdMap.get(currentSubscription.CarType__c).NumberOfAvailableCars__c >= 0
                    && currentSubscription.Status__c.equals('Contracted')
                    && currentSubscription.Car__c == null) {
                availableCarTypeOfContractedSubscriptionsSet.add(currentSubscription.CarType__c);
                subscriptionWithAvailableCarList.add(currentSubscription);
            }

        }

        if (!availableCarTypeOfContractedSubscriptionsSet.isEmpty()) {
            availableCarsByCarTypeIdMap = getAvailableCarsByCarTypeIdMap(availableCarTypeOfContractedSubscriptionsSet);

            for (Subscription__c currentSubscription : currentSubscriptionList) {
                for (Car__c availableCar : availableCarsByCarTypeIdMap.get(currentSubscription.CarType__c)) {

                    //Assign available cars to the subscriptions & update the IsAvailable field in the respective car
                    if (availableCar.IsAvailable__c) {
                        currentSubscription.Car__c = availableCar.Id;
                        currentSubscription.MonthlyAmount__c = availableCar.CarPrices__r.get(0).Price__r.MonthlyAmount__c;
                        availableCar.IsAvailable__c = false;

                        carsToBeUpdatedWithAvailability.add(availableCar);

                        //break after one available car is assigned to the current subscription
                        break;
                    }

                }
            }

            if(!carsToBeUpdatedWithAvailability.isEmpty()) {
                update carsToBeUpdatedWithAvailability;
            }

        }

    }

    //TODO: Add additional logic later for updating the Car with Kilometers Driven value for Terminated Subscriptions (Update method name too then.)
    private void unblockCarsForTerminatedSubscriptions(List<Subscription__c> currentSubscriptionList) {

        List<Car__c> carsToBeUpdatedList = new List<Car__c>();

        for(Subscription__c currentSubscription : currentSubscriptionList) {

            //Make the car from terminated subscription available again.
            if(currentSubscription.Status__c == 'Terminated' && currentSubscription.Car__c != null) {
                Car__c currentCar = new Car__c();
                currentCar.Id = currentSubscription.Car__c;
                currentCar.IsAvailable__c = true;

                carsToBeUpdatedList.add(currentCar);
            }

        }

        if(!carsToBeUpdatedList.isEmpty()) {
            update carsToBeUpdatedList;
        }

    }

    private Map<Id, List<Car__c>> getAvailableCarsByCarTypeIdMap(Set<Id> availableCarTypeOfContractedSubscriptionsSet) {

        Map<Id, List<Car__c>> availableCarsByCarTypeIdMap = new Map<Id, List<Car__c>>();

        //There should be only one active Car Price Record
        List<Car__c> availableCars = [SELECT Id, CarType__c, IsAvailable__c, (SELECT Id, Price__r.MonthlyAmount__c FROM CarPrices__r WHERE IsActive__c = true LIMIT 1) FROM Car__c WHERE CarType__c IN :availableCarTypeOfContractedSubscriptionsSet AND IsAvailable__c = true];

        for (Car__c availableCar : availableCars) {

            if (availableCarsByCarTypeIdMap.get(availableCar.CarType__c) == null) {
                availableCarsByCarTypeIdMap.put(availableCar.CarType__c, new List<Car__c>{availableCar});
            } else {
                availableCarsByCarTypeIdMap.get(availableCar.CarType__c).add(availableCar);
            }

        }

        return availableCarsByCarTypeIdMap;

    }

    private static Map<Id, CarType__c> getCarTypeByIdMap(List<Subscription__c> currentSubscriptionList) {

        Set<Id> carTypeIdSet = new Set<Id>();

        for (Subscription__c currentSubscription : currentSubscriptionList) {
            carTypeIdSet.add(currentSubscription.CarType__c);
        }

        if (carTypeByIdMap == null) {
            carTypeByIdMap = new Map<Id, CarType__c>([SELECT Id, NumberOfAvailableCars__c FROM CarType__c WHERE Id IN :carTypeIdSet]);
        }

        return carTypeByIdMap;

    }

}