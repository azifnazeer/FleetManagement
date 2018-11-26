/**
* Controller Class for Fleet Management Center Page
*/
public with sharing class FleetManagementCenterController {

    public List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList;
    public List<FleetManagementUtils.CarTypeDetailsWrapper> selectedCarTypeDetailsWrapperList;

    public Boolean hasCarType { get; set; }

    public Integer currentListSize { get; set; }
    public Integer currentListOffset { get; set; }
    public Integer paginationSize { get; set; }

    public Boolean numberOfCarsOwnedSort { get; set; }
    public Boolean numberOfCarsOnRoadSort { get; set; }
    public Boolean averageRevenuePerKmSort { get; set; }

    public Boolean SortAscending { get; set; }
    public Boolean SortDescending { get; set; }

    public String orderBy { get; set; }
    public String orderByAscDesc { get; set; }

    public Map<Id, CarManufacturer__c> carManufacturersByIdMap { get; set; }

    public List<SelectOption> manufacturerSelectOptions{set;}
    public String selectedManufacturer{get;set;}

    private final String INITIAL_SORT_ORDER = 'Desc';

    /**
    * Constuctor method for initializing the necessary data
    */
    public FleetManagementCenterController() {

        //Initializing sorting parameters
        this.numberOfCarsOwnedSort = false;
        this.numberOfCarsOnRoadSort = false;
        this.averageRevenuePerKmSort = true;

        //Initializing pagination parameters
        initializePaginationParameters();

        //Initializing manufacture map
        this.carManufacturersByIdMap = getCarManufacturersByIdMap();

        //Initializing car type wrapper list
        this.carTypeWrapperList = getCarTypeWrapperList();

        //Initializing hasCarType based on Car Type availability
        this.hasCarType = (this.carTypeWrapperList != null && this.carTypeWrapperList.size() > 0) ? true : false;

    }

    /**
    *  Method for creating and returning Car Type Wrapper List for the carTypePanel in the VF Page
    */
    public List<FleetManagementUtils.CarTypeWrapper> getCarTypeWrapperList() {

        try {
            List<CarType__c> carTypeList = Database.query(createCarTypeQuery());

            if (!carTypeList.isEmpty()) {
                this.carTypeWrapperList = createCarTypeWrapperList(carTypeList);

                return this.carTypeWrapperList;
            }

            return new List<FleetManagementUtils.CarTypeWrapper>();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Something went wrong. Please contact Administrator'));
            System.debug('Exception caught: ' + e);

            return new List<FleetManagementUtils.CarTypeWrapper>();
        }

    }

    /**
    *  Method for returning selected Car Type Details Wrapper List for the selectedCarTypesPanel in the VF Page
    */
    public List<FleetManagementUtils.CarTypeDetailsWrapper> getSelectedCarTypeDetailsWrapperList() {

        if(this.selectedCarTypeDetailsWrapperList != null) {
            return this.selectedCarTypeDetailsWrapperList;
        }

        return new List<FleetManagementUtils.CarTypeDetailsWrapper>();
    }

    /**
    *  Method for updating selected Car Type Details Wrapper List
    */
    public PageReference updateSelectedCarTypeDetailsWrapperList() {

        Boolean hasSelectedCarType = false;

        try {

            if (this.selectedCarTypeDetailsWrapperList == null) {
                this.selectedCarTypeDetailsWrapperList = new List<FleetManagementUtils.CarTypeDetailsWrapper>();
            } else {
                this.selectedCarTypeDetailsWrapperList.clear();
            }

            for (FleetManagementUtils.CarTypeWrapper carTypeWrapper : this.carTypeWrapperList) {
                if (carTypeWrapper.selected) {
                    this.selectedCarTypeDetailsWrapperList.add(new FleetManagementUtils.CarTypeDetailsWrapper(carTypeWrapper.carType));

                    if(!hasSelectedCarType) {
                        hasSelectedCarType = true;
                    }
                }
            }

            //Add a message, if no Car Types have been selected
            if(!hasSelectedCarType) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Please select atleast one Car Type for showing details'));
            }

            return null;

        } catch (Exception e) {

            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Something went wrong. Please contact Administrator'));
            System.debug('Exception caught: ' + e);

            return null;

        }

    }

    /**
    *  Method to build and return car type query
    */
    private String createCarTypeQuery() {

        String sOrderByClause = ' ORDER BY ' + (String.isEmpty(this.orderBy) ? 'Name__c' : this.orderBy);
        String sOrderByAscOrDesc = String.isEmpty(this.orderByAscDesc) ? '' : ' ' + this.orderByAscDesc + ' NULLS LAST';
        String sLimit = ' LIMIT ' + this.paginationSize;
        String sOffset = ' OFFSET ' + this.currentListOffset;

        String sSelectFromANDWhereClause =
                'SELECT Id, Name, NumberOfCarsOnRoad__c, NumberOfCarsOwned__c, NumberOfAvailableCars__c, AverageRevenuePerKm__c,'
                        + ' TotalRevenue__c, TotalMileage__c, Manufacturer__c, Manufacturer__r.Name, FirstSubscriptionDate__c,'
                        + ' (SELECT Id, TotalRevenueUntilToday__c FROM Subscriptions__r),'
                        + ' (SELECT Id, KilometersDriven__c, IsAvailable__c FROM Cars__r)'
                        + ' FROM CarType__c';

        //Add the where class only if the Manufacturer filter is applied
        if(this.selectedManufacturer != null && this.selectedManufacturer != 'all') {
            sSelectFromANDWhereClause += ' WHERE Manufacturer__c = \'' + this.selectedManufacturer + '\' ';
        }

        String finalQuery = sSelectFromANDWhereClause + sOrderByClause + sOrderByAscOrDesc + sLimit + sOffset;

        return finalQuery;

    }

    /**
    *  Method to build and return Car Type Wrapper List
    */
    private List<FleetManagementUtils.CarTypeWrapper> createCarTypeWrapperList(List<CarType__c> carTypeList) {

        List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = new List<FleetManagementUtils.CarTypeWrapper>();

        for (CarType__c carType : carTypeList) {
            carTypeWrapperList.add(new FleetManagementUtils.CarTypeWrapper(carType, carType.Cars__r));
        }

        return carTypeWrapperList;

    }

    /**
    *  Method to return a Map of Car Manufacturers with atleast one car, with Name as the key
    */
    private Map<Id, CarManufacturer__c> getCarManufacturersByIdMap() {

        if(this.carManufacturersByIdMap == null) {
            return (new Map<Id, CarManufacturer__c>([SELECT Id, Name FROM CarManufacturer__c WHERE NumberOfCarTypes__c > 0 ORDER BY Name ASC]));
        }

        return this.carManufacturersByIdMap;

    }

    /**
    *  Method to reset pagination parameters
    */
    public PageReference resetPaginationParametersAndCarTypeSelections() {

        initializePaginationParameters();

        if(this.selectedCarTypeDetailsWrapperList != null) {
            this.selectedCarTypeDetailsWrapperList.clear();
        }

        return null;

    }

    /**
    *  Action Method for closing the Fleet Management Center and going back to home page
    */
    public PageReference cancel() {

        PageReference cancelToHomePage = new PageReference('/');

        return cancelToHomePage;

    }

    /**
    *  Method to return values for Manufacturer Filter
    */
    public List<SelectOption> getManufacturerSelectOptions () {

        List<SelectOption> options = new List<SelectOption>();

        //Adding an option for showing all car types
        options.add(new SelectOption('all', 'All'));

        for(CarManufacturer__c carManufacturer : this.carManufacturersByIdMap.values()) {
            options.add(new SelectOption(carManufacturer.Id, carManufacturer.Name));
        }

        return options;

    }

    /**
    *  Method for initializing pagination parameters
    */
    public void initializePaginationParameters() {

        //Limit list size, if a manufacturer filter is applied
        if(this.selectedManufacturer != null && this.selectedManufacturer != 'all') {
            this.currentListSize = [SELECT count() FROM CarType__c WHERE Manufacturer__c = :this.carManufacturersByIdMap.get(this.selectedManufacturer).Id];
        } else {
            this.currentListSize = [SELECT count() FROM CarType__c];
        }

        this.currentListOffset = 0;
        this.paginationSize = 10;
        this.SortAscending = false;
        this.SortDescending = true;
        this.orderBy = 'NumberOfCarsOnRoad__c';
        this.orderByAscDesc = INITIAL_SORT_ORDER;

    }

    /**
    *  Following methods are used for the pagination
    */
    public PageReference first() {

        this.currentListOffset = 0;

        return null;

    }

    public PageReference previous() {

        this.currentListOffset -= this.paginationSize;

        return null;

    }

    public PageReference next() {

        this.currentListOffset += this.paginationSize;

        return null;

    }

    public PageReference last() {

        this.currentListOffset = this.paginationSize * (getTotalPages() - 1);

        return null;

    }

    public Boolean getHasPrevious() {

        if(this.currentListOffset > 0) {
            return false;
        }
        else {
            return true;

        }

    }

    public Boolean getHasNext() {

        if (this.currentListOffset + this.paginationSize < this.currentListSize) {
            return false;
        } else {
            return true;
        }

    }

    public Integer getPageNumber() {

        return this.currentListOffset / this.paginationSize + 1;

    }

    public Integer getTotalPages() {

        if (Math.mod(this.currentListSize, this.paginationSize) > 0) {
            return this.currentListSize / this.paginationSize + 1;
        } else {
            return (this.currentListSize / this.paginationSize);
        }

    }

    /**
    *  Following methods are used for sorting based on Cars Owned, Cars On Road, or Average Revenue per km
    */
    public PageReference sortByNumberOfCarsOwned() {

        this.numberOfCarsOwnedSort = true;
        this.numberOfCarsOnRoadSort = false;
        this.averageRevenuePerKmSort = false;

        return sortByValue('NumberOfCarsOwned__c');

    }

    public PageReference sortByNumberOfCarsOnRoad() {

        this.numberOfCarsOwnedSort = false;
        this.numberOfCarsOnRoadSort = true;
        this.averageRevenuePerKmSort = false;

        return sortByValue('NumberOfCarsOnRoad__c');

    }

    public PageReference sortByAverageRevenuePerKmSort() {

        this.numberOfCarsOwnedSort = false;
        this.numberOfCarsOnRoadSort = false;
        this.averageRevenuePerKmSort = true;

        return sortByValue('AverageRevenuePerKm__c');

    }

    private PageReference sortByValue(string value) {

        this.SortAscending = false;
        this.SortDescending = false;

        if (this.orderBy == value) {

            if (this.orderByAscDesc == 'Asc') {
                this.orderByAscDesc = 'Desc';
                this.SortDescending = true;
            } else {
                this.orderByAscDesc = 'Asc';
                this.SortAscending = true;
            }

        } else {

            this.orderByAscDesc = this.INITIAL_SORT_ORDER;

            if (this.orderByAscDesc == 'Asc') {
                this.SortAscending = true;
            } else {
                this.SortDescending = true;
            }

        }

        this.orderBy = value;

        return null;
    }

}