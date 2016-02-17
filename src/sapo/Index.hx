package sapo;

import haxe.web.Dispatch;
import neko.Web;
import sapo.Spod;
import sys.db.*;

class Index {
	static inline var DBPATH = ".sapo.db3";

	public static function dbReset()
	{
		Manager.cleanup();
		Manager.cnx.close();
		Manager.cnx = null;
		sys.FileSystem.deleteFile(Index.DBPATH);
		dbInit();
		
		new SurveyStatus("aberta").insert();
		new SurveyStatus("completa").insert();
		new SurveyStatus("verificada").insert();
		new SurveyStatus("CT").insert();
		new SurveyStatus("aceita").insert();
		new SurveyStatus("recusada").insert();
		new SurveyStatus("sobjudice").insert();
		
		var au = new AccessLevel("super");
		var at = new AccessLevel("telefonista");
		var as = new AccessLevel("supervisor");
		var ap = new AccessLevel("pesquisador");
		au.insert(); at.insert(); as.insert(); ap.insert();

		var arthur = new User("arthur@sapo", "Arthur Dent", ap);
		var ford = new User("ford@sapo", "Ford Prefect", as);
		arthur.insert();
		ford.insert();

		var survey1 = new Survey(ford, "Arthur's house", 945634);
		var survey2 = new Survey(arthur, "Betelgeuse, or somewhere near that planet", 6352344);
		survey1.insert();
		survey2.insert();

		var ticket1 = new Ticket(survey1, arthur, "Overpass???");
		ticket1.insert();
		new TicketMessage(ticket1, arthur, ford, "Hey, I was distrought over they wanting to build an overpass over my house").insert();
		new TicketMessage(ticket1, ford, arthur, "Don't panic... don't panic...").insert();
		
		var ticket2 = new Ticket(survey2, ford, "About Time...");
		ticket2.insert();
		new TicketMessage(ticket2, ford, arthur, "Time is an illusion, lunchtime doubly so. ").insert();
		new TicketMessage(ticket2, arthur, ford, "Very deep. You should send that in to the Reader's Digest. They've got a page for people like you.").insert();
		
	}

	static function dbInit()
	{
		Manager.initialize();
		Manager.cnx = Sqlite.open(DBPATH);
		Manager.cnx.request("PRAGMA page_size=4096");
		// later windows can't close the connection in wal mode...
		// an issue with sqlite.ndll perhaps?
		if (Sys.systemName() != "Windows") Manager.cnx.request("PRAGMA journal_mode=wal");
		var managers:Array<Manager<Dynamic>> = [User.manager, Survey.manager, Ticket.manager, TicketMessage.manager, SurveyStatus.manager, AccessLevel.manager];
		for (m in managers)
			if (!TableCreate.exists(m))
				TableCreate.create(m);
	}

	static function main()
	{
		try {
			dbInit();

			var uri = Web.getURI();
			var params = Web.getParams();
			if (uri == "/favicon.ico") return;

			var d = new Dispatch(uri, params);
			d.dispatch(new Routes());
			Manager.cnx.close();
			Manager.cnx = null;
		} catch (e:Dynamic) {
			if (Manager.cnx != null)
				Manager.cnx.close();
			Manager.cnx = null;
			neko.Lib.rethrow(e);
		}
	}
}

