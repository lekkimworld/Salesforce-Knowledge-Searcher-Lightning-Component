Source for the Proof-of-Concept for the Knowledge Searcher Lightning component as well as a video walkthru of the component and code. The code consists of an Apex class with the logic (serves as the controller for the Lightning Component) and two Aura components - one for the actual UI and one that represents each result being displayed. The component should be dragged onto the record page of the Case object using the Lightning App Builder.

In the demo org I'm using I've added a Region and a Sub Region field to the Case object with both being picklist fields and the Sub Region being a dependant picklist (dependent on Region). The values of the Region and Sub Region fields match those of the Data Category Mapping.

The Apex class is where the meat of the matter is and where the interaction with the Case object and Data Category Mapping is performed. Once loaded and initialized the Knowledge Lightning Component calls the controller that in turn will perform the search using Salesforce Object Search Language (SOSL) and return results to the component for display. The controller uses the Schema class to get access to the configured Data Category Mapping and the hierarchy of values. The controller will recursively attempt to find the most specific Data Category matching the values from the Case object the search is based on. If a Data Category is found it will be added to the SOSL search using the WITH DATA CATEGORY filter option (https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_with_datacategory.htm) and a search for the terms in the Subject field performed.

In my demo org the Data Category Mapping is called Region and is as follows:
- All
  - Europe
   - Southern Europe
   - Northern Europe
   - Western Europe
   - Eastern Europe
  - Americas
   - North America
   - South America
  - Asia
  - Africa
  - Oceania

The SOSL search is performed using the BELOW option (https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_with_datacategory_filterselectors.htm) so that any search related to a Case mapped to Europe will search in Knowledge Articles mapped to Europe and any child category (Northern Europe, Eastern Europe etc.)

Please note: This is a Proof-of-Concept so not all functionalities are implemented e.g. the search field doesn't do anything and there are no provisions for sorting etc. This should however be easy to implement.

Video walk-thru: http://www.youtube.com/watch?v=3EDi0mL_vRc

