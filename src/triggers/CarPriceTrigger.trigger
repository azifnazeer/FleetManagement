trigger CarPriceTrigger on CarPrice__c (before insert, before update) {

    if(Trigger.isBefore &&  (Trigger.isInsert  || Trigger.isUpdate)) {
        //There should be only one active car price at a time
        toggleCarPriceAvailability(Trigger.new);
    }

    private void toggleCarPriceAvailability(List<CarPrice__c> currentCarPriceList) {

        Map<Id, List<CarPrice__c>> oldCarPricesByCarIdMap = new Map<Id, List<CarPrice__c>>();
        Set<Id> carIdSet = new Set<Id>();
        List<CarPrice__c> carPricesToBeDeactivatedList = new List<CarPrice__c>();


        try {

            for (CarPrice__c currentCarPrice : currentCarPriceList) {

                if (currentCarPrice.IsActive__c) {
                    carIdSet.add(currentCarPrice.Car__c);
                }

            }

            if (!carIdSet.isEmpty()) {
                oldCarPricesByCarIdMap = getOldCarPricesByCarIdMap(carIdSet);

                for (CarPrice__c currentCarPrice : currentCarPriceList) {

                    //Make sure only one Car price record is active at a time
                    if (currentCarPrice.IsActive__c
                            && oldCarPricesByCarIdMap.get(currentCarPrice.Car__c) != null
                            && oldCarPricesByCarIdMap.get(currentCarPrice.Car__c).size() > 0) {
                        for (CarPrice__c oldCarPrice : oldCarPricesByCarIdMap.get(currentCarPrice.Car__c)) {
                            if (oldCarPrice.IsActive__c) {
                                oldCarPrice.IsActive__c = false;
                                carPricesToBeDeactivatedList.add(oldCarPrice);
                            }
                        }
                    }

                }

                if (!carPricesToBeDeactivatedList.isEmpty()) {
                    update carPricesToBeDeactivatedList;
                }
            }

        }catch(Exception e) {
            System.debug('Exception Caught: ' + e);
        }

    }

    private Map<Id, List<CarPrice__c>> getOldCarPricesByCarIdMap(Set<Id> carIdSet) {

        Map<Id, List<CarPrice__c>> oldCarPricesByCarIdMap = new Map<Id, List<CarPrice__c>>();

        List<CarPrice__c> oldCarPricesList = [SELECT Id, IsActive__c, Car__c FROM CarPrice__c WHERE Car__c IN :carIdSet];

        for(CarPrice__c oldCarPrice : oldCarPricesList) {

            if(oldCarPricesByCarIdMap.get(oldCarPrice.Car__c) == null) {
                oldCarPricesByCarIdMap.put(oldCarPrice.Car__c, new List<CarPrice__c>{oldCarPrice});
            }else {
                oldCarPricesByCarIdMap.get(oldCarPrice.Car__c).add(oldCarPrice);
            }

        }

        return oldCarPricesByCarIdMap;

    }
}