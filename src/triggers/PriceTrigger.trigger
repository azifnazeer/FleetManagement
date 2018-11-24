trigger PriceTrigger on Price__c (before insert, before update) {

    if(Trigger.isBefore &&  (Trigger.isInsert  || Trigger.isUpdate)) {
        //There should be only one active price
        togglePriceAvailability(Trigger.new);
    }

    private void togglePriceAvailability(List<Price__c> currentPriceList) {

        Map<Id, List<Price__c>> oldPricesByCarTypeIdMap = new Map<Id, List<Price__c>>();
        Set<Id> carTypeIdSet = new Set<Id>();
        List<Price__c> pricesToBeDeactivatedList = new List<Price__c>();

        for(Price__c currentPrice : currentPriceList) {

            if(currentPrice.IsActive__c) {
                carTypeIdSet.add(currentPrice.CarType__c);
            }

        }

        if(!carTypeIdSet.isEmpty()) {
            oldPricesByCarTypeIdMap = getOldPricesByCarTypeIdMap(carTypeIdSet);

            for(Price__c currentPrice : currentPriceList) {

                //Make sure only one price record is active at a time
                if(currentPrice.IsActive__c
                        && oldPricesByCarTypeIdMap.get(currentPrice.CarType__c) != null
                        && oldPricesByCarTypeIdMap.get(currentPrice.CarType__c).size() > 0) {

                    for(Price__c oldPrice : oldPricesByCarTypeIdMap.get(currentPrice.CarType__c)) {
                        if(oldPrice.IsActive__c) {
                            oldPrice.IsActive__c = false;
                            pricesToBeDeactivatedList.add(oldPrice);
                        }
                    }

                }

            }

            if(!pricesToBeDeactivatedList.isEmpty()) {
                update pricesToBeDeactivatedList;
            }
        }

    }

    private Map<Id, List<Price__c>> getOldPricesByCarTypeIdMap(Set<Id> carTypeIdSet) {

        Map<Id, List<Price__c>> oldPricesByCarTypeIdMap = new Map<Id, List<Price__c>>();

        List<Price__c> oldPricesList = [SELECT Id, IsActive__c, CarType__c FROM Price__c WHERE CarType__c IN :carTypeIdSet];

        for(Price__c oldPrice : oldPricesList) {

            if(oldPricesByCarTypeIdMap.get(oldPrice.CarType__c) == null) {
                oldPricesByCarTypeIdMap.put(oldPrice.CarType__c, new List<Price__c>{oldPrice});
            }else {
                oldPricesByCarTypeIdMap.get(oldPrice.CarType__c).add(oldPrice);
            }

        }

        return oldPricesByCarTypeIdMap;

    }

}