public with sharing class FleetManagementCenterController {

    public List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList;
    public List<FleetManagementUtils.CarWrapper> selectedCarWrapperList;

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

    public Map<Id, CarManufacturer__c> carManufacturersByNameMap { get; set; }

    public List<SelectOption> manufacturerSelectOptions{set;}
    public String selectedManufacturer{get;set;}

    private final String INITIAL_SORT_ORDER = 'Desc';

    public FleetManagementCenterController() {

        //Initializing sorting parameters
        this.numberOfCarsOwnedSort = false;
        this.numberOfCarsOnRoadSort = false;
        this.averageRevenuePerKmSort = true;

        //Initializing pagination parameters
        initializePaginationParameters();

        //Initializing manufacture map
        this.carManufacturersByNameMap = getCarManufacturersByIdMap();

        //Initializing car type wrapper list
        this.carTypeWrapperList = getCarTypeWrapperList();

        //Initializing hasCarType based on Car Type availability
        this.hasCarType = (this.carTypeWrapperList != null && this.carTypeWrapperList.size() > 0) ? true : false;

    }

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

    public List<FleetManagementUtils.CarWrapper> getSelectedCarWrapperList() {

        return this.selectedCarWrapperList;

    }

    public PageReference updateSelectedCarWrapperList() {
        Boolean hasSelectedCarType = false;

        try {

            if (this.selectedCarWrapperList == null) {
                this.selectedCarWrapperList = new List<FleetManagementUtils.CarWrapper>();
            } else {
                this.selectedCarWrapperList.clear();
            }

            for (FleetManagementUtils.CarTypeWrapper carTypeWrapper : this.carTypeWrapperList) {
                if (carTypeWrapper.selected) {
                    this.selectedCarWrapperList.add(new FleetManagementUtils.CarWrapper(carTypeWrapper.carType));

                    if(!hasSelectedCarType) {
                        hasSelectedCarType = true;
                    }
                }
            }

            //Add a message, if no Car Types have been selected
            if(!hasSelectedCarType) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Please select atleast one Car Type to show the details'));
            }

            return null;

        } catch (Exception e) {

            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Something went wrong. Please contact Administrator'));
            System.debug('Exception caught: ' + e);

            return null;

        }

    }

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

    private List<FleetManagementUtils.CarTypeWrapper> createCarTypeWrapperList(List<CarType__c> carTypeList) {

        List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = new List<FleetManagementUtils.CarTypeWrapper>();

        for (CarType__c carType : carTypeList) {
            carTypeWrapperList.add(new FleetManagementUtils.CarTypeWrapper(carType, carType.Cars__r));
        }

        return carTypeWrapperList;

    }

    private Map<Id, CarManufacturer__c> getCarManufacturersByIdMap() {

        if(this.carManufacturersByNameMap == null) {
            return (new Map<Id, CarManufacturer__c>([SELECT Id, Name FROM CarManufacturer__c WHERE NumberOfCarTypes__c > 0 ORDER BY Name ASC]));
        }

        return this.carManufacturersByNameMap;

    }

    public PageReference resetPaginationParametersAndCarTypeSelections() {

        initializePaginationParameters();

        if(this.selectedCarWrapperList != null) {
            this.selectedCarWrapperList.clear();
        }

        return null;

    }

    public PageReference cancel() {

        PageReference cancelToHomePage = new PageReference('/');

        return cancelToHomePage;

    }

    public List<SelectOption> getManufacturerSelectOptions () {

        List<SelectOption> options = new List<SelectOption>();

        for(CarManufacturer__c carManufacturer : this.carManufacturersByNameMap.values()) {
            options.add(new SelectOption(carManufacturer.Id, carManufacturer.Name));
        }

        return options;

    }

    public void initializePaginationParameters() {

        if(this.selectedManufacturer != null && this.selectedManufacturer != 'all') {
            this.currentListSize = [SELECT count() FROM CarType__c WHERE Manufacturer__c = :this.carManufacturersByNameMap.get(this.selectedManufacturer).Id];
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