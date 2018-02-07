public with sharing class KnowledgeSearcher_LCC {
    private static final String KNOWLEDGE_CATEGORY_OBJECT = 'KnowledgeArticleVersion';
    private static final String KNOWLEDGE_CATEGORY_FIELD_MAPPING_NAME = 'Region';
    private static final List<String> DATA_CATEGORY_FIELDS = new List<String>{'Region__c', 'Sub_Region__c'};

    @AuraEnabled
    public static List<KnowledgeArticleVersion> search(String recordId) {
        // look up the case
        List<Case> cases = [SELECT Subject, Region__c, Sub_Region__c From Case WHERE Id =: recordId];
        if (cases.size() != 1) {
            throw new AuraHandledException('Unexpected result when trying to locate Case with Id <' + recordId + '>');
        }

        // get case
        Case c = cases[0];

        // look for data category mapping
        final String categoryMapping = findMatchingDataCategory(c);

        // create sosl
        String sosl = null;
        if (String.isEmpty(categoryMapping)) {
            // search without any category mapping
            sosl = 'FIND {' + String.escapeSingleQuotes(c.Subject) + '} IN ALL FIELDS RETURNING KnowledgeArticleVersion(ArticleNumber,KnowledgeArticleId,LastPublishedDate,Title,ValidationStatus)';
        } else {
            // search using found category mapping
            sosl = 'FIND {' + String.escapeSingleQuotes(c.Subject) + '} IN ALL FIELDS RETURNING KnowledgeArticleVersion(ArticleNumber,KnowledgeArticleId,LastPublishedDate,Title,ValidationStatus) WITH DATA CATEGORY Region__c BELOW ' + categoryMapping + '__c';
        }

        // do search
        Search.SearchResults searchResults = Search.find(sosl);
        List<Search.SearchResult> articlelist = searchResults.get(KNOWLEDGE_CATEGORY_OBJECT);
        List<KnowledgeArticleVersion> articles = new List<KnowledgeArticleVersion>();
        for (Search.SearchResult searchResult : articleList) {
            KnowledgeArticleVersion article = (KnowledgeArticleVersion) searchResult.getSObject();
            articles.add(article);
        }
        return articles;
    }

    private static String findMatchingDataCategory(Case c) {
        // ask for data categories for knowledge
        final List <String> objType = new List<String>{KNOWLEDGE_CATEGORY_OBJECT};
        final List<Schema.DescribeDataCategoryGroupResult> describeCategoryResult = Schema.describeDataCategoryGroups(objType);

        // loop through data categories for knowledge looking for the correct mapping and
        // create DataCategoryGroupSobjectTypePair object
        final List<Schema.DataCategoryGroupSobjectTypePair> pairs = new List<Schema.DataCategoryGroupSobjectTypePair>();
        for (DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
            if (singleResult.getName().equals(KNOWLEDGE_CATEGORY_FIELD_MAPPING_NAME)) {
                // found the one we are looking for - add pair
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject(singleResult.getSobject());
                p.setDataCategoryGroupName(singleResult.getName());
                pairs.add(p);
            }
        }
        if (pairs.isEmpty()) throw new AuraHandledException('Unable to find requested Schema.DataCategoryGroupSobjectTypePair for <' + KNOWLEDGE_CATEGORY_OBJECT + '> called <' + KNOWLEDGE_CATEGORY_FIELD_MAPPING_NAME + '>');

        // get describe for root element and loop although there can only be one...
        final List<Schema.DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
        for (DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
            // get the top categories and get the first level
            final DataCategory topLevel = singleResult.getTopCategories().get(0);

            // recurse into children
            Integer fieldCounter = 0;
            String result = recurseDataCategoryHierarchy(c, fieldCounter, topLevel.getChildCategories());
            if (String.isNotEmpty(result)) return result;
        }
        return null;
    }

    private static String recurseDataCategoryHierarchy(Case c, Integer fieldCounter, List<DataCategory> cats) {
        // get field value if applicable
        if (fieldCounter == DATA_CATEGORY_FIELDS.size()) return null;
        final String fieldName = DATA_CATEGORY_FIELDS.get(fieldCounter++);
        final String fieldValue = (String)c.get(fieldName);
        if (String.isEmpty(fieldValue)) return null;

        // loop and attempt to find
        for (DataCategory cat : cats) {
            if (cat.getLabel().equals(fieldValue)) {
                // yay found it - recurse
                String result = recurseDataCategoryHierarchy(c, fieldCounter, cat.getChildCategories());
                if (String.isEmpty(result)) {
                    // no matching child found - return this one
                    return cat.getName();
                } else {
                    return result;
                }
            }
        }

        // not found
        return null;
    }

}