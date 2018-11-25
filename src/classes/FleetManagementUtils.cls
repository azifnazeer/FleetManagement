public with sharing class FleetManagementUtils {

    public class CarTypeWrapper {

        //Variable to hold Car Type fields
        public Id carTypeId {get; set;}
        public String Name {get; set;}
        public Integer numberOfCarsOwned {get; set;}
        public Integer numberOfCarsOnRoad {get; set;}

        public Decimal totalRevenue {get; set;}
        public Decimal averageRevenuePerCar {get; set;}

        //List tp hold related Cars of a specific Car Type
        public List<Car__c> carList {get; set;}

        //Boolean value to hold the selection of specific Car Type
        public Boolean selected {get; set;}

        //Constructor to initialise a Car Type Wrapper Object and set the selected boolean value to false
        public CarTypeWrapper(CarType__c carType, List<Car__c> carList, List<Subscription__c> subscriptionList) {

            this.carTypeId = carType.Id;
            this.Name = carType.Name;
            this.numberOfCarsOwned = Integer.valueOf(carType.NumberOfCarsOwned__c);
            this.numberOfCarsOnRoad = Integer.valueOf(carType.NumberOfCarsOnRoad__c);
            this.totalRevenue = FleetManagementUtils.getTotalRevenue(subscriptionList);
            this.averageRevenuePerCar = (this.totalRevenue / this.numberOfCarsOwned).setScale(2);
            this.selected = false;

            this.carList = carList;

        }

    }

    public class CarWrapper {

        public Id carId {get; set;}
        public String carTypeName {get; set;}
        public String manufacturer {get; set;}
        public Integer kilometersDriven {get; set;}
        public String isAvailable {get; set;}

        public CarWrapper(Car__c car) {

            this.carId = car.Id;
            this.carTypeName = car.CarType__r.Name;
            this.manufacturer = car.CarType__r.Manufacturer__r.Name;
            this.kilometersDriven = Integer.valueOf(car.KilometersDriven__c);
            this.isAvailable = car.IsAvailable__c ? 'Available' : 'Not Available';

        }

    }

    public static Decimal getTotalRevenue(List<Subscription__c> subscriptionList) {

        Decimal totalRevenue = 0.0;

        if(!subscriptionList.isEmpty()) {
            for(Subscription__c subList : subscriptionList) {
                totalRevenue += subList.TotalRevenueUntilToday__c;
            }
        }

        return totalRevenue;
    }

}