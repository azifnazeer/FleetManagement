public with sharing class FleetManagementUtils {

    public class CarTypeWrapper {

        //Variable to hold Car Type fields
        public CarType__c carType {get; set;}
        public String name {get; set;}
        public Integer numberOfCarsOwned {get; set;}
        public Integer numberOfCarsOnRoad {get; set;}

        //List tp hold related Cars of a specific Car Type
        public List<Car__c> carList {get; set;}

        //Boolean value to hold the selection of specific Car Type
        public Boolean selected {get; set;}

        //Constructor to initialise a Car Type Wrapper Object and set the selected boolean value to false
        public CarTypeWrapper(CarType__c carType, List<Car__c> carList) {

            this.carType = carType;
            this.name = carType.Name;
            this.numberOfCarsOwned = Integer.valueOf(carType.NumberOfCarsOwned__c);
            this.numberOfCarsOnRoad = Integer.valueOf(carType.NumberOfCarsOnRoad__c);
            this.selected = false;

            this.carList = carList;

        }

    }

    public class CarWrapper {

        public String carTypeName {get; set;}
        public String manufacturer {get; set;}
        public Integer numberOfAvailableCars {get; set;}
        public Integer totalMileage {get; set;}
        public Integer averageMileage {get; set;}
        public String firstSubscriptionDate {get; set;}
        public Decimal totalRevenue {get; set;}
        public Decimal averageRevenuePerCar {get; set;}
        public Decimal averageRevenuePerKm {get; set;}


        public CarWrapper(CarType__c carType) {

            this.carTypeName = carType.Name;
            this.manufacturer = carType.Manufacturer__r.Name;
            this.numberOfAvailableCars = Integer.valueOf(carType.NumberOfAvailableCars__c);
            this.totalRevenue = FleetManagementUtils.getTotalRevenue(carType.Subscriptions__r);
            this.averageRevenuePerCar = (this.totalRevenue / carType.NumberOfCarsOwned__c).setScale(2);
            this.firstSubscriptionDate = carType.FirstSubscriptionDate__c.format();
            this.totalMileage = FleetManagementUtils.getTotalMileage(carType.Cars__r);
            this.averageMileage = Integer.valueOf(this.totalMileage / carType.NumberOfCarsOwned__c);
            this.averageRevenuePerKm = (this.totalRevenue / this.totalMileage).setScale(2);

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

    public static Integer getTotalMileage(List<Car__c> carList) {

        Decimal totalMileage = 0.0;

        if(!carList.isEmpty()) {
            for(Car__c car : carList) {
                totalMileage += car.KilometersDriven__c;
            }
        }

        return Integer.valueOf(totalMileage);
    }

}