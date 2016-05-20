package sapo;

import common.Dispatch;
import common.EnvVars;
import common.Web;
import common.crypto.Password;
import common.db.MoreTypes;
import comn.LocalEnqueuer;
import comn.Spod;
import neko.Random;
import sapo.model.TicketModel;
import sapo.route.AccessControl;
import sapo.spod.Other;
import sapo.spod.Survey;
import sapo.spod.Ticket;
import sapo.spod.User;
import sys.db.*;

class Context {
	static var DBPATH = Sys.getEnv("SAPO_DB");
	static var STATICPATH = Sys.getEnv("STATIC_FILES");

	public static var version(default,null) = { commit : Version.getGitCommitHash() }
	public static var now(default,null):HaxeTimestamp;
	public static var db(default,null):common.db.AutocommitConnection;
	public static var loop(default,null):Context;
	public static var comn(default,null):LocalEnqueuer;

	public static var glAnalyticsId:Null<String>;

	var dispatch:Dispatch;

	public var uri(default,null):String;
	public var params(default,null):Map<String,String>;
	public var method(default,null):String;

	public var session(default,null):Null<Session>;
	public var user(default,null):Null<User>;
	public var group(default,null):Null<Group>;
	public var privilege(default,null):Null<Privilege>;

	static function __init__()
	{
		// google analytics
		var gaid = Sys.getEnv(GL_ANALYTICS_ID);
		if (gaid != null && StringTools.trim(gaid) != "")
			glAnalyticsId = gaid;
	}

	static function dbInit()
	{
		var managers:Array<Manager<Dynamic>> = [
			Group.manager,
			QueuedMessage.manager,
			SapoVersion.manager,
			Session.manager,
			Ticket.manager,
			TicketMessage.manager,
			TicketRecipient.manager,
			TicketSubscription.manager,
			TicketSort.manager,
			Token.manager,
			User.manager
		];
		function viewExists(name) {
			return try {
				db.request('SELECT * FROM $name LIMIT 1');
				true;
			} catch (e:Dynamic) {
				false;
			}
		}

		for (m in managers)
			if (!TableCreate.exists(m))
				TableCreate.create(m);

		if (!viewExists("UpdatedSurvey")) {
			db.request("CREATE VIEW UpdatedSurvey AS SELECT
						MAX(id) as session_id,
						old_survey_id,
						MAX(syncTimestamp) as syncTimestamp
					FROM Survey GROUP BY old_survey_id");
		}
		
		if (!viewExists("SurveyGroupStatus"))
		{
			db.request("CREATE VIEW SurveyGroupStatus AS 
						SELECT 
						s.user_id as user_id, 
						s.`group` as `group`, 
						COUNT(*) as pesqGrupo, 
						SUM(
							CASE WHEN 
							(checkSV = 1 OR checkSV IS NULL) 
							AND 
							(checkCT = 1 OR checkCT IS NULL) 
							AND 
							(checkCQ = 1 OR checkCQ IS NULL)  
							AND 
							((checkSV+checkCT+checkCQ != 3)  OR (checkSV+checkCT+checkCQ is null)) 
							THEN 1 
							ELSE 0 END
						) AS Completa,
						MIN(s.checkSV) AS checkSV,
						MIN(s.checkCT) AS checkCT,
						MIN(s.checkCQ) AS checkCQ,
						SUM(CASE WHEN checkSV = 0 AND checkCT = 0 AND checkCQ = 0 THEN 1 ELSE 0 END) as allFalse, 
						SUM(CASE WHEN checkSV = 0 OR checkCT = 0 OR checkCQ = 0 THEN 1 ELSE 0 END) as hasFalse, 
						SUM(CASE WHEN checkSV = 1 AND checkCT = 1 AND checkCQ = 1 THEN 1 ELSE 0 END) as isTrue
						FROM Survey s 
						JOIN UpdatedSurvey us 
							ON s.old_survey_id = us.old_survey_id AND s.syncTimestamp = us.syncTimestamp 
						GROUP BY s.user_id, s.`group` 
						ORDER BY s.user_id, s.`group`");
		}
		
		if (!viewExists("SurveyCheckStatus"))
		{
			db.request("CREATE VIEW SurveyCheckStatus AS 
						SELECT 
						s.id as id,
						s.`group` as `group`,
						s.isPhoned as isPhoned,
						s.checkSV as checkSV,
						CASE WHEN s.checkCT IS NULL THEN sg.checkCT ELSE s.checkCT END as checkCT,
						s.checkCQ AS checkCQ,
						s.date_completed as date_completed
						FROM Survey s 
						JOIN SurveyGroupStatus sg 
							ON 
								s.user_id = sg.`user_id` 
									AND 
								s.`group` = sg.`group`");		
		}

		comn = new LocalEnqueuer(QueuedMessage.manager);
	}

	static function updateStatics()
	{
		var sep = ";";
		var staticsPackage = "common.spod.statics.";
		var bpath = STATICPATH;
		if (bpath == null) {
			trace('WARNING using deprecated fix path to statics');
			bpath = "./private/csvs";
		}

		if (!sys.FileSystem.exists(bpath)) {
			trace('WARNING path to static files does not exist: $bpath');
			return;
		}

		var dir = sys.FileSystem.readDirectory(bpath);
		if (dir.length == 0) {
			trace('WARNING no static files to load in path: $bpath');
			return;
		}

		for (p in dir) {
			if (!StringTools.endsWith(p,".csv")) {
				trace('Ignoring $p: not CSV');
				continue;
			}

			var clName = p.split(".")[0];
			var cl = Type.resolveClass(staticsPackage + clName);
			if (cl == null) {
				trace('Ignoring $p: no table for it');
				continue;
			}
			var p = haxe.io.Path.normalize(haxe.io.Path.join([bpath, p]));
			var mtime = sys.FileSystem.stat(p).mtime;

			startTransaction();
			var v = SapoVersion.manager.get(p, true);
			if (v != null && v.updated_at > mtime) {
				commit();
				continue;
			}

			var bytes = sys.io.File.getBytes(p);
			var hash = haxe.crypto.Sha1.make(bytes).toHex();
			trace('Loading $p');
			trace("... deleting everything");
			db.request('DELETE FROM `$clName`');
			trace("... inserting new values");
			var file = new haxe.io.BytesInput(bytes);
			try {
				var fields = file.readLine().split(sep);
				while (true) {
					var params = file.readLine().split(sep);
					var instance = Type.createEmptyInstance(cl);
					for (i in 0...fields.length)
						Reflect.setField(instance, fields[i], params[i]);
					instance.insert();
				}
			} catch (e:haxe.io.Eof) {
				if (v != null) {
					v.version = hash;
					v.update();
				} else {
					v = new SapoVersion(p, hash);
					v.insert();
				}
				commit();
				trace('Updated $p');
				file.close();
			} catch (e:Dynamic) {
				rollback();
				neko.Lib.rethrow(e);
			}
		}
	}

	function new(uri:String, params:Map<String, String>, method:String, session:Null<Session>)
	{
		this.uri = uri;
		this.params = params;
		dispatch = new Dispatch(uri, params, method);

		if (session == null)
			return;
		if (session.expired(now)) {
			session.expire();
			session.update();
			return;
		}
		this.session = session;
		this.user = session.user;
		this.group = user.group;
		this.privilege = group.privilege;
	}

	public static function init(?now)
	{
		updateClock();
		common.spod.InitDB.run();
		db = Manager.cnx;
		dbInit();
		updateStatics();
	}

	public static function updateClock()
	{
		now = Sys.time()*1e3;
	}

	public static function startTransaction()
		db.request("BEGIN");

	public static function commit()
		db.request("COMMIT");

	public static function rollback()
		db.request("ROLLBACK");

	public static function shutdown()
	{
		if (db == null) return;
		db.close();
		db = Manager.cnx = null;
	}

#if tink_template
	public static function iterate()
	{
		updateClock();

		var uri = Web.getURI();
		var params = Web.getParams();
		var method = Web.getMethod();

		// treat visibly empty params as missing
		var cparams = [ for (k in params.keys()) if (StringTools.trim(params.get(k)).length > 0) k => params.get(k) ];

		var key = Session.COOKIE_KEY;
		var cookies = Web.getAllCookies();
		if (cookies.exists(key) && cookies[key].length > 1)
			trace('WARNING multiple (${cookies[key].length}) values for cookie ${key}; we can\'t handle that yet');
		var sid = Web.getCookies()[key];  // FIXME
		var session = Session.manager.get(sid);

		loop = new Context(uri, cparams, method, session);

		trace(loop.session);
		if (loop.session != null) trace(loop.session.expires_at.toDate());
		if (loop.session != null) trace(loop.session.expired());
		if (loop.session != null && loop.session.expired_at != null) trace(loop.session.expired_at.toDate());

		// log if we're loosing any params
		var aparams = Web.getAllParams();
		for (p in aparams.keys())
			if (aparams[p].length > 1)
				trace('WARNING multiple (${aparams[p].length}) values for param $p; we can\'t handle that yet');

		loop.dispatch.onMeta = AccessControl.onDispatchMeta;
		try {
			loop.dispatch.dispatch(new sapo.route.RootRoutes());
		} catch (e:AccessControlError) {
			Context.shutdown();
			trace('Access control error: $e');
			var url = Web.getURI();
			if (e.match(EACNotAuthorized(_))) {
				Web.redirect("/403.html");
			} else if (url != "" && uri != "/" && uri != "/login" && Web.getMethod().toLowerCase() == "get") {
				url += "?" + [
					for (k in Web.getParams().keys())
						'${StringTools.urlEncode(k)}=${StringTools.urlEncode(Web.getParams().get(k))}'
				].join("&");
				Web.redirect('/login?redirect=${StringTools.urlEncode(url)}');
			} else {
				Web.redirect("/login");
			}
		} catch (e:DispatchError) {
			Context.shutdown();
			trace('Dispatch error: $e');
			Web.redirect("/404.html");
		}
	}
#end
}

