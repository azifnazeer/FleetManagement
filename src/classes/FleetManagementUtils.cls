/**
*  Utility page for Fleet Management Center
*/
public with sharing class FleetManagementUtils {

    /**
    *  Wrapper Class for Car Type Object
    */
    public class CarTypeWrapper {

        public CarType__c carType {get; set;}
        public String name {get; set;}
        public Integer numberOfCarsOwned {get; set;}
        public Integer numberOfCarsOnRoad {get; set;}
        public Decimal averageRevenuePerKm {get; set;}

        //List tp hold related Cars of a specific Car Type
        public List<Car__c> carList {get; set;}

        //Boolean value to hold the selection of specific Car Type
        public Boolean selected {get; set;}

        //Constructor to initialise a Car Type Wrapper Object and set the selected boolean value to false
        public CarTypeWrapper(CarType__c carType, List<Car__c> carList) {

            this.carType = carType;
            this.name = carType.Name;
            this.carList = carList;
            this.numberOfCarsOwned = Integer.valueOf(carType.NumberOfCarsOwned__c);
            this.numberOfCarsOnRoad = Integer.valueOf(carType.NumberOfCarsOnRoad__c);
            this.averageRevenuePerKm = carType.AverageRevenuePerKm__c;

            this.selected = false;

        }

    }

    /**
    *  Wrapper Class for Car Type Object, with more aggregated information for the details section of Fleet Management Center
    */
    public class CarTypeDetailsWrapper {

        public String carTypeName {get; set;}
        public String manufacturer {get; set;}
        public Integer numberOfAvailableCars {get; set;}
        public Integer totalMileage {get; set;}
        public Integer averageMileage {get; set;}
        public String firstSubscriptionDate {get; set;}
        public Decimal totalRevenue {get; set;}
        public Decimal averageRevenuePerCar {get; set;}


        public CarTypeDetailsWrapper(CarType__c carType) {

            this.carTypeName = carType.Name;
            this.manufacturer = carType.Manufacturer__r.Name;
            this.numberOfAvailableCars = Integer.valueOf(carType.NumberOfAvailableCars__c);
            this.totalRevenue = carType.TotalRevenue__c;
            this.totalMileage = Integer.valueOf(carType.TotalMileage__c);
            this.averageRevenuePerCar = (this.totalRevenue / carType.NumberOfCarsOwned__c).setScale(2);
            this.firstSubscriptionDate = carType.FirstSubscriptionDate__c.format();
            this.averageMileage = Integer.valueOf(this.totalMileage / carType.NumberOfCarsOwned__c);

        }

    }

}