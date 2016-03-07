package sapo.js;

import haxe.Json;
import js.Browser;
import js.jquery.*;
import js.Lib;

class FormCache {
	static var viewname = Browser.window.location.pathname;
	
	static function onSubmit(_)
	{
		var local = Browser.getLocalStorage();
		new JQuery("select, input").each(function(i, elem)
		{			
			var cur = new JQuery(elem);
			var isSelect = cur.is("select");
			var field = isSelect ? "select" : "input";
			var fieldtype = isSelect ? "" : cur.attr("type");
			var fieldname = cur.attr("name");
			var arrKey = [viewname, field, fieldtype, fieldname];
			
			local.setItem(arrKey.join(";"), cur.val());
			
			
		});
	}

	static function main()
	{
		new JQuery().ready(function() {
			
			var local = Browser.getLocalStorage();
			if (local == null) {
				trace("No local storage");
				return;
			}
			var i = 0;
			while (i < local.length) {
				var key = local.key(i);
				
				var arrKey = key.split(";");
				
				if (arrKey.length < 4 || viewname != arrKey[0])
				{
					i++;
					continue;
				}
				var fieldname = arrKey[3] != "" ? '[name=\'' + arrKey[3] + '\']' : "";
				var typename = arrKey[2] != "" ? '[type=\'' + arrKey[2] + '\']' : "";
				new JQuery(arrKey[1] + fieldname+typename).val(local.getItem(key));
				//new JQuery("select[name='" + key + "']").val(local.getItem(key));
				local.removeItem(key);
			}
			new JQuery("form[name='filter']").submit(onSubmit);
		});

	}
}

