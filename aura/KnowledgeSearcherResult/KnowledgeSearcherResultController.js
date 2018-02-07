({
    navigate: function(cmp, event, helper) {
        var evt = $A.get("e.force:navigateToSObject");
        evt.setParams({
			"recordId": cmp.get('v.article').KnowledgeArticleId
		});
		evt.fire();
    }
})