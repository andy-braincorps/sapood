package sapo;

import common.crypto.Password;
import common.db.MoreTypes;
import common.spod.EnumSPOD;
import common.spod.InitDB;
import common.spod.statics.*;
import sapo.model.*;
import sapo.spod.Other;
import sapo.spod.Survey;
import sapo.spod.Ticket;
import sapo.spod.User;
import StringTools.*;

private typedef Groups = {
	surveyors : Group,
	supervisors : Group,
	phoneOperators : Group,
	superUsers : Group,
	lessSuperUsers:Group
}

private typedef Users = {
	surveyors : Array<User>,
	supervisors : Array<User>,
	phoneOperators : Array<User>,
	superUsers : Array<User>
}

private typedef FakeSurveys = Array<Survey>;

private typedef Tickets = Array<Ticket>;

class Populate {
	static var rnd = new neko.Random();
	static var id = 0;

	static function rndPick<T>(a:Array<T>)
		return a[rnd.int(a.length)];

	static function rndDate(?from:HaxeTimestamp, ?maxDelta:Float)
	{
		if (from == null) from = Context.now.delta(-2*$week);
		var limitDelta = (Context.now:Float)-(from:Float);
		if (maxDelta == null || maxDelta > limitDelta) maxDelta = limitDelta;
		return (from + rnd.float()*maxDelta:HaxeTimestamp);
	}

	static function rndTrue(?p:Null<Float>)
	{
		if (p == null) p = .5;
		return rnd.int(1000) < p*1000;
	}

	static function rndNullTrue(?pnull:Null<Float>, ?ptrue:Null<Float>)
		return rndTrue(pnull) ? null : rndTrue(ptrue);

	static function makeGroups()
	{
		var surveyors = new Group(PSurveyor, "Pesquisador");
		var supervisors = new Group(PSupervisor, "Supervisor");
		var phoneOperators = new Group(PPhoneOperator, "Central telefônica");
		var lessSuperUsers = new Group(PSuperUser, "Central de qualidade");
		var superUsers = new Group(PSuperUser, "Controle");
		for (g in [surveyors, supervisors, phoneOperators, lessSuperUsers, superUsers])
			g.insert();
		return { surveyors : surveyors, supervisors : supervisors,
				phoneOperators : phoneOperators, superUsers : superUsers, lessSuperUsers : lessSuperUsers };
	}

	static function makeUsers(g:Groups)
	{
		var alice = new User(g.superUsers, new EmailAddress("alice@sapo"), "Alice Aria");
		var ford = new User(g.superUsers, new EmailAddress("ford@sapo"), "Ford Frederik");
		var judite = new User(g.phoneOperators, new EmailAddress("judite@sapo"), "Judite Julia");
		var magentoCol = [ for (i in 0...3) new User(g.supervisors, new EmailAddress('magento.${i+1}@sapo'),
				'Magento Maria #${i+1}') ];
		var morgana = new User(g.lessSuperUsers, new EmailAddress("morgana@sapo"), "Morgana Moura");
		for (u in [alice, ford, judite, morgana].concat(magentoCol)) {
			u.password = Password.make("secret");
			u.insert();
		}
		var maneCol = [ for (i in 0...12) new User(g.surveyors, new EmailAddress('mane.${i+1}@sapo'),
				'Mané Maurício #${i+1}', magentoCol[i%magentoCol.length]) ];
		for (u in maneCol) {
			u.password = Password.make("secret");
			u.insert();
		}
		return { surveyors : maneCol, supervisors : magentoCol,
				phoneOperators : [judite], superUsers : [alice, ford] };
	}

	static function makeSurvey(groups:Groups, users:Users, magic:Int, it:Int)
	{
		var s = new Survey();

		s.user_id = rndPick(users.surveyors).id;
		s.lastPageVisited = "END";
		s.isValid = false;
		s.isRestored = rndTrue();
		s.date_create = rndDate();

		s.endereco_id = rnd.int(10*magic);
		s.estadoPesquisa = EstadoPesquisa.Concluida;
		s.bairro = "Asa Centro Oeste";
		s.logradouro = "Rua GWD";
		s.numero = "5000";
		s.lote = "Lote 123";
		s.estrato = " Estrato Logit " + it;
		s.old_survey_id = it;
		s.pin = "ASD-Qer3-qwee";
		s.tentativa_id = 1;
		s.checkCT = rndNullTrue();
		s.checkSV = rndNullTrue();
		s.checkCQ = rndNullTrue();
		s.isPhoned = rndTrue(.1);
		s.date_started = s.date_create;
		s.date_finished = rndDate(s.date_create, HaxeTimestamp.resolveTime(5*$day));
		s.date_completed = s.date_finished;
		s.syncTimestamp = rndDate(s.date_completed, HaxeTimestamp.resolveTime($day));

		s.group = (1 + it%10)*(users.surveyors.length)*10 + it % s.user_id;

		if (rndTrue()) s.tentativa_id = rnd.int(10);
		if (rndTrue(.3)) s.paid = rndTrue(.5);
		if (rndTrue(.1)) {
			s.codigoFormularioPapel = Std.string(rnd.int(Std.int(magic/10)));
			s.dataInicioPesquisaPapel = rndDate(s.date_create);
			s.dataFimPesquisaPapel = rndDate(s.dataInicioPesquisaPapel);
		}
		if (rndTrue()) s.date_started = rndDate(s.date_create);
		if (rndTrue()) s.date_finished = rndDate(s.date_started);
		if (rndTrue()) s.date_completed = rndDate(s.date_started);

		// for (f in Survey.manager.dbInfos().fields) {
		// 	if (!f.isNull && !f.t.match(DId) && Reflect.getProperty(s, f.name) == null)
		// 		throw 'filed ${f.name} is null';
		// }
		s.insert();
		return s;
	}

	static function makeSurveys(groups:Groups, users:Users)
	{
		var magic = 100;
		var surveys = [ for (i in 0...magic) makeSurvey(groups, users, magic, i) ];
		return surveys;
	}

	static function makeFamily(s:Survey)
	{
		var f = new Familia();
		f.aguaEncanada = Type.createEnumIndex(AguaEncanada, rnd.int(2));
		f.anoVeiculoMaisRecente = Type.createEnumIndex(AnoVeiculoMaisRecente, rnd.int(8));
		f.banheiros = rnd.int(3);
		f.bicicletas = rnd.int(1);
		f.condicaoMoradia = Type.createEnumIndex(CondicaoMoradia, rnd.int(7));
		f.date = DateTools.delta(s.date_create, 1000 * 60 * rnd.int(60));
		f.empregadosDomesticos = Type.createEnumIndex(EmpregadosDomesticos, rnd.int(4));
		f.isDeleted = false;
		f.isEdited = 0;
		f.motos = rnd.int(3);
		f.nomeContato = "Red Herring " + s.old_survey_id;
		f.numeroResidentes = rnd.int(4);
		f.ocupacaoDomicilio = Type.createEnumIndex(OcupacaoDomicilio, rnd.int(4));
		f.old_id = id++;
		f.old_survey_id = s.old_survey_id;
		f.quartos = rnd.int(4);
		f.recebeBolsaFamilia = rndTrue();
		f.rendaDomiciliar = Type.createEnumIndex(RendaDomiciliar, rnd.int(12));
		f.ruaPavimentada_id = rndTrue();
		f.survey = s;
		f.syncTimestamp = s.syncTimestamp;
		f.telefoneContato = "9999-9999";
		f.tentativa_id = 1;
		f.tipoImovel = Type.createEnumIndex(TipoImovel, rnd.int(7));
		f.tvCabo_id = rndTrue();
		f.vagaPropriaEstacionamento_id = rndTrue();
		f.veiculos = rnd.int(4);
		f.insert();
		return f;
	}

	static function makeResident(f:Familia, it:Int)
	{
		var s = f.survey;
		var m = new Morador();
		m.atividadeMorador = Type.createEnumIndex(AtividadeMorador, rnd.int(15));
		m.date = DateTools.delta(f.date, 1000 * 60 * rnd.int(60));
		m.familia = f;
		m.genero_id = rnd.int(1);
		m.grauInstrucao = Type.createEnumIndex(GrauInstrucao, rnd.int(12));
		m.idade = Type.createEnumIndex(Idade, rnd.int(14));
		m.isDeleted = false;
		m.isEdited = 0;
		m.motivoSemViagem = Type.createEnumIndex(MotivoSemViagem, rnd.int(3));
		m.nomeMorador = "Zacarias José " + it;
		m.old_id = id++;
		m.old_survey_id = s.old_survey_id;
		m.portadorNecessidadesEspeciais = Type.createEnumIndex(PortadorNecessidadesEspeciais, rnd.int(7));
		m.possuiHabilitacao_id = rndTrue();
		m.proprioMorador_id = rndTrue();
		m.quemResponde = null;
		m.setorAtividadeEmpresaPrivada = Type.createEnumIndex(SetorAtividadeEmpresaPrivada, rnd.int(8));
		m.setorAtividadeEmpresaPublica = Type.createEnumIndex(SetorAtividadeEmpresaPublica, rnd.int(4));
		m.situacaoFamiliar = Type.createEnumIndex(SituacaoFamiliar, rnd.int(10));
		m.survey = s;
		m.syncTimestamp = s.syncTimestamp;
		m.insert();
		return m;
	}

	static function makePoint(m:Morador, it:Int)
	{
		var s = m.survey;
		var p = new Ponto();
		p.city_id = rnd.int(10000);
		p.complement_id = rnd.int(1000);
		p.complement_two_id = rnd.int(1000);
		p.complement2_str = "random";
		p.copiedFrom = null;
		p.date = DateTools.delta(m.date, 1000 * 60 * rnd.float());
		p.isEdited = rndTrue(.1) ? rnd.int(10) : 0;
		p.isDeleted = rndTrue(.05);
		p.isPontoProximo = rndTrue();
		p.morador = m;
		p.motivo = Type.createEnumIndex(Motivo, rnd.int(14));
		p.motivoOutraPessoa = Type.createEnumIndex(Motivo, rnd.int(14));
		p.old_id = id++;
		p.old_survey_id = s.old_survey_id;
		p.pontoProx = null;
		p.ordem = it;
		p.ref = null;
		p.ref_str = "Random place ";
		p.regadm_id = rnd.int(9999);
		p.street_id = rnd.int(9999);
		p.survey = s;
		p.syncTimestamp = m.syncTimestamp;
		p.tempo_chegada = lpad(Std.string(rnd.int(24)), "0", 2) + ":" + lpad(Std.string(rnd.int(60)), "0", 2);
		p.tempo_saida = lpad(Std.string(rnd.int(24)), "0", 2) + ":" + lpad(Std.string(rnd.int(60)), "0", 2);
		p.uf = UF.manager.get(1);
		p.insert();
		return p;
	}

	static function makeMode(fp:Ponto, p:Ponto, it:Int)
	{
		var s = p.survey;
		var m = p.morador;
		var mo = new Modo();
		mo.date = DateTools.delta(p.date, 1000 * 60 * rnd.int(40));
		mo.isEdited = rndTrue(.1) ? rnd.int(10) : 0;
		mo.isDeleted = rndTrue(.05);
		mo.estacaoDesembarque = EstacaoMetro.manager.get(rnd.int(20));
		mo.estacaoEmbarque = EstacaoMetro.manager.get(rnd.int(20));
		mo.firstpoint = fp;
		mo.secondpoint = p;
		mo.formaPagamento = Type.createEnumIndex(FormaPagamento, rnd.int(7));
		mo.isDeleted = false;
		mo.isEdited = 0;
		mo.linhaOnibus = LinhaOnibus.manager.get(rnd.int(50));
		mo.linhaOnibus_str = "Linha XXX" + it;
		mo.meiotransporte = Type.createEnumIndex(MeioTransporte, rnd.int(16));
		mo.morador = m;
		mo.ordem = it;
		mo.old_id = id++;
		mo.old_morador_id = m.old_id;
		mo.old_survey_id = s.old_survey_id;
		mo.survey = s;
		mo.syncTimestamp = s.syncTimestamp;
		mo.tipoEstacionamento = Type.createEnumIndex(TipoEstacionamento, rnd.int(8));
		mo.valorViagem = rnd.float() * rnd.int(40);
		mo.insert();
		return mo;
	}

	static function makeTickets(groups:Groups, users:Users, surveyCol:FakeSurveys)
	{
		var authorCol = users.superUsers.concat(users.supervisors);
		var recipientCol = authorCol.concat(users.phoneOperators);  // TODO create some for groups too
		var ticketCol = [];
		for (i in 0...20) {
			var s = surveyCol[i%surveyCol.length];
			var a = authorCol[i%authorCol.length];
			var r = recipientCol[(recipientCol.length + i)%recipientCol.length];
			TicketModel.open(s, a,
					'Lorem ${s.id} ipsum ${a.name} ${r.name}',
					'Heyy!!  Just letting you know I found an issue with survey ${s.id}',
					r);
		}
		var ticket1 = TicketModel.open(surveyCol[0], users.superUsers[0],
				"Overpass???",
				"Hey, I was distrought over they wanting to build an overpass over my house",
				groups.superUsers);
		TicketModel.addMessage(ticket1, users.superUsers[1], "Don't panic... don't panic...");
		ticketCol.push(ticket1);
		var ticket2 = TicketModel.open(surveyCol[1], users.superUsers[1],
				"About Time...",
				"Time is an illusion, luchtime doubly so.",
				groups.phoneOperators);
		TicketModel.addMessage(ticket2, users.superUsers[0], "Very deep. You should send that in to the Reader's Digest. They've got a page for people like you.");
		ticketCol.push(ticket2);
		return ticketCol;
	}

	static function makeData(g, u)
	{
		var surveys = makeSurveys(g, u);
		var families = [ for (s in surveys) makeFamily(s) ];
		for (f in families) {
			var residents = [ for (i in 0...f.numeroResidentes) makeResident(f, i) ];
			for (r in residents) {
				var points = [ for (i in 0...(3+rnd.int(2))) makePoint(r, i) ];
				for (pi in 1...points.length) {
					for (i in 0...(1+rnd.int(5)))
						makeMode(points[pi-1], points[pi], i);
				}
			}
		}
		return surveys;
	}

	@:access(sapo.Context)
	public static function reset()
	{
		Context.shutdown();
		if(sys.FileSystem.exists(Context.DBPATH)) {
			trace('RESET: deleting ${Context.DBPATH}');
			sys.FileSystem.deleteFile(Context.DBPATH);
		}
		Context.init();

		rnd.setSeed(42);
		id = 0;

		Context.startTransaction();
		try {
			var groups = makeGroups();
			var users = makeUsers(groups);

			var surveys = makeData(groups, users);
			var tickets = makeTickets(groups,users, surveys);
		} catch (e:Dynamic) {
			Context.rollback();
			neko.Lib.rethrow(e);
		}
		Context.commit();
	}
}

