package sync;
import common.tools.StringTools;
import haxe.macro.Expr;
class Macros {
	
	public static macro function setEnumField(field : Expr, new_entry : Expr, old_entry : Expr, survey_id : Expr)
	{
		return macro {
			var norm_field = $field.split("_")[0];
			
			var e = Type.resolveEnum("common.spod." + StringTools.capitalize(norm_field));
			if (Macros.checkEnumValue(e, Reflect.field($old_entry, $field), $survey_id))
			{
				Reflect.setProperty($new_entry, norm_field, Macros.getStaticEnum(e, Reflect.field($old_entry, $field)));
			}
		}
	}
	
	
	public static macro function getStaticEnum(target : Expr, old_value : Expr)
	{
		return macro {
			if($old_value != null)
				$target.createByIndex(refValue.get(Type.getEnumName($target)).get($old_value));
			else
				null;
		}
	}
	
	
	public static macro function checkEnumValue(target : Expr, old_value : Expr, survey_id : Expr)
	{
		return macro {
			var name = Type.getEnumName($target);
			
			if (refValue.get(name) == null)
			{
				Macros.warnTable(name, null, null, $survey_id);
				false;
			}
			else if($old_value != null && refValue.get(Type.getEnumName($target)).get($old_value) == null)
			{
				Macros.warnEnum(name, $old_value, $survey_id);
				false;
			}
			else
				true;
		};
	}	
	
	public static macro function validateEntry(tableClass : Expr, ignoreParams : Expr, whereParams : Expr, curEntry : Expr)
	{
		return macro {
			//trace('iddddd  + ' + $curEntry.id);
			var fulltblname = Type.getClassName($tableClass).split(".");
			var tblname = fulltblname[fulltblname.length -1];
			
			var str = " WHERE ";
			
			var i = 0;
			while(i < $whereParams.length)
			{
				if (i != 0)
					str = str + " AND ";
				str = str + $whereParams[i].key + "=" + $whereParams[i].value;
				i++;
			}
			//trace('iddddd 222 + ' + $curEntry.id);
			var old_entry = $tableClass.manager.unsafeObject("SELECT * FROM " + tblname + str+" ORDER BY syncTimestamp DESC LIMIT 1", false);
			//trace('iddddd 333 + ' + $curEntry.id);
			var shouldInsert = false;
			if (!insertMode)
			{
				for (info in $tableClass.manager.dbInfos().fields)
				{
					var field = info.name;
					
					if($ignoreParams.indexOf(field) == -1 && Std.string(Reflect.getProperty($curEntry, field)) != Std.string(Reflect.getProperty(old_entry, field)))
					{
						//If no field "date_completed", then null :)
						if (old_entry != null && Reflect.field(old_entry, 'date_completed') != null && (Reflect.field(old_entry, 'date_edited') - Date.now().getTime()) > 1000 * 60 * 60 * 6 )
							Macros.warning("Sync will override this value " + old_entry.id + ". Please don't sync completed entries.", old_entry.old_survey_id);
						return true;
					}
				}
				
				$curEntry = old_entry;				
			}
			else
			{
				//trace("wololooo");
				try				
				{
					//trace("11111111111111111");
					//trace(Reflect.hasField(old_entry, "isDeleted"));
					//Qualquer tabela que não a session					
					//trace('iddddd  + 444 ' + $curEntry.id);
					if (Reflect.hasField(old_entry,"isDeleted"))
					{
						//trace("Nigga stole my bike!");
						if(Reflect.field(old_entry, "isDeleted") == false)
							$curEntry.insert();
						else
							$curEntry = old_entry;
					}
					else
					{
						//trace("hello darkness my old friend");
						//trace($curEntry);
						$curEntry.insert();
						//trace("kthnxbye");
					}
					//trace("check?");
					var v = ours.get(tblname) != null ? ours.get(tblname) : 0;
					ours.set(tblname, v + 1);
					//trace("aaaaaaaaargh");
				}
				catch (e : Dynamic)
				{
					trace(e);
					Macros.criticalError(tblname, e);
				}
			}
			
			var v = syncex.get(tblname) != null ? syncex.get(tblname) : 0;
			syncex.set(tblname, v + 1);
			
			old_entry;
		}
	}
	
	
	public static macro function criticalError(table : Expr, error : Expr)
	{
		return macro {
				enq.enqueue(new comn.message.Slack( { text : "Critical error on table " + $table + " : " + $error , username : "SyncBot" } ));
				trace("Critical error on table " + $table + " : " + $error);
		}
	}
	public static macro function warning(msg : Expr, survey_id : Expr)
	{
		return macro {
				ticket("Sync Warning", $msg, $survey_id);
		}
	}
	public static macro function extraField(table : Expr, field : Expr)
	{
		return macro {
				enq.enqueue(new comn.message.Slack( { text : "Unexpected field " +$field +  " on table " + $table , username : "SyncBot" } ));
				throw "Unexpected field " +$field +  " on table " + $table;
		}
	}
	
	public static macro function warnTable(table : Expr, field : Expr, val : Expr, survey_id : Expr)
	{
		return macro {
			//TODO: Implementar comunicacao
			if ($val != null)
			{
				trace("Table " + $table + " has a problem on field " + $field + ": Unexpected value " + $val);
				ticket("SYNC WARNING", "Table " + $table + " has a problem on field " + $field + ": Unexpected value " + $val, $survey_id);
			}
			else
			{
				trace("Table " + $table + " doesn't exist!");
				ticket("SYNC WARNING", "Table " + $table + " doesn't exist!", $survey_id);
			}
			
			warning++;
		}
	}
	
	public static macro function warnEnum(enumName : Expr, value : Expr, survey_id : Expr)
	{
		//TODO: Implementar comunicacao
		return macro {
			trace("Enum " + $enumName + " doesn't have val " + $value);
			ticket("SYNC HELPER TABLE WARNING", "SAPOOD HELPER TABLE " + $enumName + " doesn't have value " + $value, $survey_id);
			
			warning++;
		}
	}
}
