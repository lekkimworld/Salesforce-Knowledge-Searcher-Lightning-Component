({
    doInit: function(cmp, helper) {
		var action = cmp.get('c.search');
		var args = {
		    'recordId': cmp.get('v.recordId')
  		}
  		action.setParams(args);
  		action.setCallback(this, function(response) {
  			var state = response.getState();
  			if (state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set('v.articles', result);
				console.log(result);
  			} else {
  			    console.log(response.getError());
     		}
  		})
  		$A.enqueueAction(action);
    }
})