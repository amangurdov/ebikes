public with sharing class ProductController {
    static Integer PAGE_SIZE = 9;

    public class Filters {
        @AuraEnabled
        public String searchKey { get; set; }
        @AuraEnabled
        public Decimal maxPrice { get; set; }
        @AuraEnabled
        public Integer recordsPerPage { get; set; }
        @AuraEnabled
        public String[] categories { get; set; }
        @AuraEnabled
        public String[] materials { get; set; }
        @AuraEnabled
        public String[] levels { get; set; }
        @AuraEnabled
        public String[] framecolors { get; set; }
        
    }

    @AuraEnabled(Cacheable=true)
    public static PagedResult getProducts(Filters filters, Integer pageNumber) {
        String key, whereClause = '';
        Decimal maxPrice;
        Integer recordsPerPage = 9;
        String[] categories, materials, levels, framecolors, criteria = new List<String>{};
        if (filters != null) {
            maxPrice = filters.maxPrice;
            materials = filters.materials;
            levels = filters.levels;
            if (!String.isEmpty(filters.searchKey)) {
                key = '%' + filters.searchKey + '%';
                criteria.add('Name LIKE :key');
            }
            if (filters.maxPrice >= 0) {
                maxPrice = filters.maxPrice;
                criteria.add('MSRP__c <= :maxPrice');
            }
            if (filters.recordsPerPage >= 0) {
                recordsPerPage = filters.recordsPerPage;
            }
            if (filters.categories != null) {
                categories = filters.categories;
                criteria.add('Category__c IN :categories');
            }
            if (filters.levels != null) {
                levels = filters.levels;
                criteria.add('Level__c IN :levels');
            }
            if (filters.materials != null) {
                materials = filters.materials;
                criteria.add('Material__c IN :materials');
            }

            if (filters.framecolors != null) {
                framecolors = filters.framecolors;
                criteria.add('Frame_Color__c IN :framecolors');
            }
            if (criteria.size() > 0) {
                whereClause = 'WHERE ' + String.join(criteria, ' AND ');
            }
        }
        Integer pageSize = recordsPerPage;
        Integer offset = (pageNumber - 1) * pageSize;
        PagedResult result = new PagedResult();
        result.pageSize = pageSize;
        result.pageNumber = pageNumber;
        result.totalItemCount = Database.countQuery(
            'SELECT count() FROM Product__c ' + whereClause
        );
        result.records = Database.query(
            'SELECT Id, Name, MSRP__c, Description__c, Category__c, Level__c, Picture_URL__c, Material__c FROM Product__c ' +
            whereClause +
            ' WITH SECURITY_ENFORCED' +
            ' ORDER BY Name LIMIT :pageSize OFFSET :offset'
        );
        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static Product__c[] getSimilarProducts(Id productId, Id familyId) {
        return [
            SELECT
                Id,
                Name,
                MSRP__c,
                Description__c,
                Category__c,
                Level__c,
                Picture_URL__c,
                Material__c
            FROM Product__c
            WHERE Product_Family__c = :familyId AND Id != :productId
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled(Cacheable=true)
    public static String makeInOutStock(string productName){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://vpsdevds2-viasat.cs32.force.com/paymentservice/services/apexrest/ebikestockcheck/?pname=' + productName.replaceAll(' ', '+'));
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', 'abc123');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        return res.getBody();
    }
}