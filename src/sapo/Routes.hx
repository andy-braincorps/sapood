package sapo;

import haxe.web.Dispatch;
import common.Web;
import sapo.Spod;

class TinkRoutes 
{
	public function doTickets(d:Dispatch)
		d.dispatch(new TicketRoutes());
		
	public function doLogin()
		Sys.println(sapo.view.Login.render());

	public function doDefault()
		Sys.println(sapo.view.Summary.render());
		
	public function doRegistration()
		Sys.println(sapo.view.Registration.render());
		
	public function doPayment()
		Sys.println(sapo.view.Payment.render());
		
	public function doSurveys()
		Sys.println(sapo.view.Surveys.render());
	
	public function doSurvey(s:sapo.NewSurvey)
		Sys.println(sapo.view.Survey.render(s));

	public function new() {}
}

class TicketRoutes
{
	public function doDefault(?args:{ ?ofUser:User, ?inbox:String, ?recipient:String, ?state:String })
	{
		if (args == null) args = { };
		Sys.println(sapo.view.Tickets.render(args.ofUser));
	}
	
	public function doSearch(?args:{ ?ofUser:User, ?ticket:Ticket, ?survey:NewSurvey })
	{
		if (args == null) args = { };
		Sys.println(sapo.view.Tickets.render(args.ofUser));
	}
	
	public function new() {}
}

class Routes 
{
	public function doDefault()
	{
		Web.redirect("/tink/login");
	}

	public function doReset()
	{
		Index.dbReset();
		Web.redirect("/");
	}

	public function doTink(d:Dispatch)
		d.dispatch(new TinkRoutes());

	public function new() {}
}

