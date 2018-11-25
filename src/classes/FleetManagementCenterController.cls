public with sharing class FleetManagementCenterController {

    public List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList;
    public List<FleetManagementUtils.CarWrapper> selectedCarWrapperList;

    public Boolean hasCarType { get; set; }

    public Integer currentListSize { get; set; }
    public Integer currentListOffset { get; set; }
    public Integer paginationSize { get; set; }

    public Boolean numberOfCarsOwnedSort { get; set; }
    public Boolean numberOfCarsOnRoadSort { get; set; }

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
        this.numberOfCarsOwnedSort = true;
        this.numberOfCarsOnRoadSort = false;

        //Initialize pagination parameters
        initializePaginationParameters();

        //Initialize manufacture id list with all possible manufacturers
        this.carManufacturersByNameMap = getCarManufacturersByIdMap();

        this.carTypeWrapperList = getCarTypeWrapperList();

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

    public PageReference setSelectedCarWrapperList() {

        if(this.selectedCarWrapperList == null) {
            this.selectedCarWrapperList = new List<FleetManagementUtils.CarWrapper>();
        } else {
            this.selectedCarWrapperList.clear();
        }

        for (FleetManagementUtils.CarTypeWrapper carTypeWrapper : this.carTypeWrapperList) {
            System.debug('***'+carTypeWrapper.selected);
            if (carTypeWrapper.selected) {
                for (Car__c car : carTypeWrapper.carList) {
                    this.selectedCarWrapperList.add(new FleetManagementUtils.CarWrapper(car));
                }
            }
        }

        return null;

    }

    private String createCarTypeQuery() {
        String sOrderByClause = ' ORDER BY ' + (String.isEmpty(this.orderBy) ? 'Name__c' : this.orderBy);
        String sOrderByAscOrDesc = String.isEmpty(this.orderByAscDesc) ? '' : ' ' + this.orderByAscDesc + ' NULLS LAST';
        String sLimit = ' LIMIT ' + this.paginationSize;
        String sOffset = ' OFFSET ' + this.currentListOffset;
        //String sManufacturerIdClause = '(\'\')';

        String sSelectFromANDWhereClause =
                'SELECT Id, Name, NumberOfCarsOnRoad__c, NumberOfCarsOwned__c, Manufacturer__c,'
                        + ' (SELECT Id, TotalRevenueUntilToday__c FROM Subscriptions__r),'
                        + ' (SELECT Id, KilometersDriven__c, IsAvailable__c, CarType__r.Name, CarType__r.Manufacturer__r.Name FROM Cars__r)'
                        + ' FROM CarType__c';

        if(this.selectedManufacturer != null && this.selectedManufacturer != 'all') {
            sSelectFromANDWhereClause += ' WHERE Manufacturer__c = \'' + this.selectedManufacturer + '\' ';
        }

        String finalQuery = sSelectFromANDWhereClause + sOrderByClause + sOrderByAscOrDesc + sLimit + sOffset;

        System.debug(finalQuery);

        return finalQuery;
    }

    private List<FleetManagementUtils.CarTypeWrapper> createCarTypeWrapperList(List<CarType__c> carTypeList) {
        List<FleetManagementUtils.CarTypeWrapper> carTypeWrapperList = new List<FleetManagementUtils.CarTypeWrapper>();

        for (CarType__c carType : carTypeList) {
            carTypeWrapperList.add(new FleetManagementUtils.CarTypeWrapper(carType, carType.Cars__r, carType.Subscriptions__r));
        }

        return carTypeWrapperList;
    }

    private Map<Id, CarManufacturer__c> getCarManufacturersByIdMap() {

        if(this.carManufacturersByNameMap == null) {
            return (new Map<Id, CarManufacturer__c>([SELECT Id, Name FROM CarManufacturer__c WHERE NumberOfCarTypes__c > 0]));
        }

        return this.carManufacturersByNameMap;

    }

    public PageReference resetPaginationParametersAndDeselectCarTypeSelections() {
        initializePaginationParameters();

        for(FleetManagementUtils.CarTypeWrapper carTypeWrapper : this.carTypeWrapperList) {
            if(carTypeWrapper.selected) {
                carTypeWrapper.selected = false;
            }
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
        currentListOffset = 0;

        return null;
    }

    public PageReference previous() {
        currentListOffset -= paginationSize;

        return null;
    }

    public PageReference next() {
        currentListOffset += paginationSize;

        return null;
    }

    public PageReference last() {
        currentListOffset = paginationSize * (getTotalPages() - 1);

        return null;
    }

    public Boolean getHasPrevious() {
        if (currentListOffset > 0) return false; else return true;
    }

    public Boolean getHasNext() {
        if (currentListOffset + paginationSize < currentListSize) return false; else return true;
    }

    public Integer getPageNumber() {
        return currentListOffset / paginationSize + 1;
    }

    public Integer getTotalPages() {
        if (Math.mod(currentListSize, paginationSize) > 0) {
            return currentListSize / paginationSize + 1;
        } else {
            return (currentListSize / paginationSize);
        }
    }

    public PageReference sortByNumberOfCarsOwned() {
        this.numberOfCarsOwnedSort = true;
        this.numberOfCarsOnRoadSort = false;

        return sortByValue('NumberOfCarsOwned__c');
    }

    public PageReference sortByNumberOfCarsOnRoad() {
        this.numberOfCarsOwnedSort = false;
        this.numberOfCarsOnRoadSort = true;

        return sortByValue('NumberOfCarsOnRoad__c');
    }

    private PageReference sortByValue(string value) {
        SortAscending = false;
        SortDescending = false;

        if (orderBy == value) {

            if (orderByAscDesc == 'Asc') {
                orderByAscDesc = 'Desc';
                SortDescending = true;
            } else {
                orderByAscDesc = 'Asc';
                SortAscending = true;
            }

        } else {

            orderByAscDesc = INITIAL_SORT_ORDER;

            if (orderByAscDesc == 'Asc') {
                SortAscending = true;
            } else {
                SortDescending = true;
            }

        }

        orderBy = value;

        return null;
    }

}