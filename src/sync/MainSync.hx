package sync;
import common.db.MoreTypes.HaxeTimestamp;
import common.spod.EnumSPOD;
import sapo.Populate;
import common.spod.statics.EstacaoMetro;
import common.spod.statics.LinhaOnibus;
import common.spod.statics.Referencias;
import common.spod.statics.UF;
import comn.LocalEnqueuer;
import comn.Spod.QueuedMessage;
import haxe.Http;
import haxe.Json;
import haxe.Log;
import haxe.PosInfos;
import common.spod.InitDB;
import sapo.Context;
import sapo.spod.Survey;
import sapo.spod.Ticket;
import sapo.spod.User;
import sapo.spod.User.Group;
import sys.db.TableCreate;

import sys.db.Connection;
import sys.db.Manager;
import sys.db.Mysql;
import sys.db.Types.SFloat;
import sys.FileSystem;
import sys.io.File;
import common.tools.StringTools;

/**
 * ...
 * @author Caio
 */
using Lambda;
//TODO: MUDAR NOMES!
class MainSync
{

	static var targetCnx : Connection;

	static var sessHash : Map<Int, Survey>;
	static var famHash : Map<Int, Familia>;
	static var morHash : Map<Int, Morador>;
	static var pointhash : Map<Int,Ponto>;
	static var curTimestamp : Float;
	static var refValue : Map<String,Map<Int,Int>>;

	//User_id , Group, Count
	static var userGroup : Map<Int, Map<Int,Int>>;

	static var syncex : Map<String,Int>;

	static var ours : Map<String,Int>;
	static var warning : Int = 0;

	static var enq : LocalEnqueuer;
	
	static var SYNC_USER : String;
	
	
	static var TARGET_GROUP : String;
	
	static var group: Group;
	static var author : User;

	public static function main()
	{
		SYNC_USER = Sys.getEnv("SYNC_USER");
		TARGET_GROUP = Sys.getEnv("TARGET_GROUP");
		
		Log.trace = function(txt : Dynamic, ?infos : PosInfos)
		{
			var v = File.append("Log.txt");
			v.writeString(txt + '\n');
			v.close();

			Sys.println(infos.className + " " + infos.lineNumber + ": " + txt);
		}
		//TODO:Apagar
		{
			//TODO: Linkar lugar correto no DB
			//Populate.reset();
			//InitDB.run();
			Context.init();
			if (!TableCreate.exists(QueuedMessage.manager))
				TableCreate.create(QueuedMessage.manager);
			enq = new LocalEnqueuer(QueuedMessage.manager);

		}
		//END
		
		author = User.manager.get(Std.parseInt(SYNC_USER), false);
		group = Group.manager.select($name == TARGET_GROUP, null, false);
		
		syncex = new Map();
		ours = new Map();

		if (!FileSystem.exists("./private/cnxstring"))
		{
			trace("No cnxstring file!");
			return;
		}
		serverTimestamp();
		
		var cnxstring = Json.parse(File.getContent("./private/cnxstring"));
		targetCnx = Mysql.connect(Reflect.field(cnxstring, "DFTTPODD"));
		targetCnx.request("START TRANSACTION");
		
		
		curTimestamp = targetCnx.request("SELECT MAX(timestamp) as max FROM SyncMap").results().first().max;
		
		var resUsers = Manager.cnx.request("SELECT id, user_id, `group` FROM Survey s JOIN UpdatedSurvey us ON s.id = us.session_id ORDER BY user_id, `group`");
		userGroup = new Map();
		for (r in resUsers)
		{
			var submap : Map<Int, Int>;
			if (userGroup.get(r.user_id) == null)
				submap = new Map();
			
			else
				submap = userGroup.get(r.user_id);

			var v = submap.get(r.group) != null ? submap.get(r.group) : 0;
			submap.set(r.group, v + 1);

			userGroup.set(r.user_id, submap);
		}
		
		var latestsync = Manager.cnx.request("SELECT MAX(syncTimestamp) as timestamp FROM Survey").results().first().timestamp;
		
		
		//Todos os valores de enums -> usa as keys "EnumName" e "Old_val" => "New_val" para conversão das entradas originais para as novas
		//A estrutura é Map<String,Map<Int,Int>>
		refValue = populateHash();

		// Query -> ../../extras/main.sql
		//Session_id only
		var updateVars = targetCnx.request("SELECT DISTINCT session_id FROM ((SELECT ep.session_id as session_id FROM SyncMap sm join EnderecoProp ep ON sm.tbl = 'EnderecoProp' AND sm.new_id = ep.id AND sm.timestamp > "+latestsync+") UNION ALL (SELECT  s.id as session_id FROM SyncMap sm JOIN Session s ON sm.tbl = 'Session' AND sm.new_id = s.id AND sm.timestamp > "+latestsync+") UNION ALL ( select f.session_id as session_id FROM SyncMap sm JOIN Familia f ON f.id = sm.new_id AND sm.tbl = 'Familia'  AND sm.timestamp > "+latestsync+") UNION ALL (select  m.session_id as session_id FROM SyncMap sm JOIN Morador m ON m.id = sm.new_id AND sm.tbl = 'Morador'  AND sm.timestamp > "+latestsync+") UNION ( select  p.session_id as session_id FROM SyncMap sm JOIN Ponto p ON  sm.tbl = 'Ponto' AND p.id = sm.new_id  AND sm.timestamp > "+latestsync+") UNION ALL (select m.session_id as session_id FROM SyncMap sm JOIN Modo m ON m.id = sm.new_id AND sm.tbl = 'Modo'  AND sm.timestamp >"+latestsync+")) ack WHERE session_id IS NOT NULL ORDER BY session_id ASC").results().map(function(v) { return v.session_id; } ).array();
		
		

		//Hash old_id -> new instance
		sessHash = new Map<Int, Survey>();
		famHash = new Map<Int, Familia>();
		morHash = new Map<Int, Morador>();
		pointhash = new Map<Int, Ponto>();

		for (u in updateVars)
		{
			var shouldInsert = processSessionID(u, false);
		}


		for (k in syncex.keys())
		{
			var v = ours.get(k);
			v = (v != null) ? v : 0;
			var txt = "Table " + k + ": Syncex detected " + syncex.get(k) + " entries. Updated : " + v;
			enq.enqueue(new comn.message.Slack({ text : txt , username : "SyncBot" } ));
		}

		trace("Done with only " + warning + " warnings!");
		enq.enqueue(new comn.message.Slack( { text : "Done with only " + warning + " warnings!" , username : "SyncBot" } ));

		Manager.cleanup();
		Manager.cnx.close();
		targetCnx.close();

	}

	static function processSessionID(u : Int, insertMode : Bool) : Bool
	{
		for (p in [processSession, processFamilia, processMorador, processPonto, processModo, processOcorrencias]) {
			if (p(u, insertMode))
				return processSessionID(u, true);
		}
		return true;
	}

	static function processSession(sid : Int, insertMode : Bool) : Bool
	{
		var dbSession = targetCnx.request("SELECT * FROM Session WHERE id = " + sid).results().first();

		var new_sess = new Survey();
		for (f in Reflect.fields(dbSession))
		{
			switch(f)
			{
				case "id":
					new_sess.old_survey_id = dbSession.id;
				//Conversao de bool (hoorray)
				case "isValid", "isRestored":
					Reflect.setField(new_sess, f, (Reflect.field(dbSession, f) == 1));
				//Copia simples de campo
				case "user_id", "tentativa_id", "lastPageVisited", "codigoFormularioPapel",
				"endereco_id", "pin", "latitude", "longitude",
				 "bairro", "logradouro", "numero", "complemento","lote","estrato":
					Reflect.setField(new_sess, f, Reflect.field(dbSession, f));
				//Datas:
				case "dataInicioPesquisaPapel", "dataFimPesquisaPapel",
				"date_create", "date_started", "date_finished", "date_completed":
					var rawfield = Reflect.field(dbSession, f);
					var x : HaxeTimestamp = rawfield == null ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
					Reflect.setField(new_sess, f, x);
				case "json":
						if (checkJson("Survey", Reflect.field(dbSession, f)))
							Reflect.setField(new_sess, f, Reflect.field(dbSession, f));
				//Enum
				case "estadoPesquisa_id":
					Macros.setEnumField(f, new_sess, dbSession, sid);
				case "ponto","gps_id","client_ip", "closedFromIndex":
					continue;
				default:
					Macros.extraField("Survey", f);
			}
		}

		new_sess.syncTimestamp = curTimestamp;
		if (insertMode)
		{
			var groups = userGroup.get(new_sess.user_id);
			var biggest = 1;
			if (groups == null)
				groups = new Map();

			for(k in groups.keys())
			{
				if (k > biggest)
					biggest = k;
			}

			if (groups.get(biggest) == null || groups.get(biggest) < 10)
			{
				var curval = groups.get(biggest) != null ? groups.get(biggest) : 0;
				groups.set(biggest, curval + 1);
				userGroup.set(new_sess.user_id, groups);

				new_sess.group = biggest;
				var sort = new CTicket();
				sort.sort(new_sess.user_id, new_sess.group, biggest, new_sess);
			}
			else
			{
				var v = biggest + 1;
				groups.set(v, 1);
				userGroup.set(new_sess.user_id, groups);

				new_sess.group = v;
				
				var sort = new CTicket();
				sort.sort(new_sess.user_id, new_sess.group, biggest, new_sess);
			}

		}

		//o = old_entry from Macros.validateEntry (old_entry is an old reference to the same survey)
		var o : Survey = Macros.validateEntry(Survey, ["syncTimestamp", "id","paid","date_paid","paymentRef","checkSV","checkCT","checkCQ","group","date_edited"], [ { key : "old_survey_id", value : new_sess.old_survey_id } ], new_sess);
		
		//Update fields from 
		if (insertMode && o != null && o.date_completed != null )
		{
			new_sess.lock();
			new_sess.paid = o.paid;
			new_sess.paymentRef = o.paymentRef;
			new_sess.date_paid = o.date_paid;
			new_sess.checkSV = o.checkSV;
			new_sess.checkCT = o.checkCT;
			new_sess.checkCQ = o.checkCQ;
			new_sess.isPhoned = o.isPhoned;
			new_sess.date_edited = o.date_edited;
			new_sess.group = o.group;
			new_sess.update();
		}

		sessHash.set(new_sess.old_survey_id, new_sess);
		return false;
	}

	static function processFamilia(old_sid : Int, insertMode : Bool) : Bool
	{
		var dbFam = targetCnx.request("SELECT * FROM Familia WHERE session_id = " + old_sid + " ORDER BY id").results();
		var new_familia = new Familia();

		for (f in dbFam)
		{
			for (field in Reflect.fields(f))
			{
				switch(field)
				{
					case "id":
						new_familia.old_id = f.id;
					case "session_id":
						new_familia.survey = sessHash.get(f.session_id);
						new_familia.old_survey_id = f.session_id;
					case "ocupacaoDomicilio_id", "condicaoMoradia_id", "tipoImovel_id",
					"aguaEncanada_id", "anoVeiculoMaisRecente_id", "empregadosDomesticos_id",
					"rendaDomiciliar_id":
						Macros.setEnumField(field, new_familia, f, old_sid);
					
					//Fields ctrl+c ctrl+v
					case "isEdited", "numeroResidentes", "banheiros", "quartos",
					"veiculos", "bicicletas", "motos",  "nomeContato", "telefoneContato","tentativa_id":
						Reflect.setField(new_familia, field, Reflect.field(f, field));
					case "date":
							var rawfield = Reflect.field(f, field);
							var x : HaxeTimestamp = (rawfield == null) ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
							Reflect.setField(new_familia, field, x);
					case "json":
						if (checkJson("Familia", Reflect.field(f, field)))
							Reflect.setField(new_familia, field, Reflect.field(f, field));
					//Bool simples
					case "isDeleted","recebeBolsaFamilia_id":
						Reflect.setProperty(new_familia, field, Reflect.field(f, field) == 1);
					//Conversao enum -> bool
					case "tvCabo_id","vagaPropriaEstacionamento_id, ruaPavimentada_id":
						var v = Reflect.field(f, field);
						Reflect.setField(new_familia, field, (v != 3) ? (v == 1) : null);
					case "gps_id", "editedNumeroResidentes", "editsNumeroResidentes",
					"editedNomeContato", "editsNomeContato", "editedTelefoneContato",
					"editsTelefoneContato", "editedRendaDomiciliar", "editsRendaDomiciliar",
					"codigoReagendamento":
						continue;
					default:
						Macros.extraField("Familia", field);
				}
			}
			new_familia.syncTimestamp = curTimestamp;

			Macros.validateEntry(Familia, ["syncTimestamp", "id"], [ { key : "old_id" , value : new_familia.old_id }, { key : "old_survey_id", value : new_familia.old_survey_id } ], new_familia);

			famHash.set(new_familia.old_id, new_familia);
		}
		return false;
	}

	static function processMorador(old_session : Int, insertMode : Bool) : Bool
	{
		var dbMorador = targetCnx.request("SELECT * FROM Morador WHERE session_id = " + old_session + " ORDER BY familia_id").results();
		for (m in dbMorador)
		{
			var new_morador = new Morador();
			for (field in Reflect.fields(m))
			{
				switch(field)
				{
					case "id":
						new_morador.old_id = m.id;
					case "session_id":
						new_morador.survey = sessHash.get(m.session_id);
						new_morador.old_survey_id = m.session_id;
					case "familia_id":
						new_morador.familia = famHash.get(m.familia_id);
					case "quemResponde_id":
						new_morador.quemResponde = morHash.get(m.quemResponde_id);
					//Enums
					case "idade_id", "grauInstrucao_id", "situacaoFamiliar_id", "atividadeMorador_id", "portadorNecessidadesEspeciais_id", "motivoSemViagem_id","setorAtividadeEmpresaPrivada_id","setorAtividadeEmpresaPublica_id":
						Macros.setEnumField(field, new_morador, m, old_session);
					//Bools
					case "isDeleted", "possuiHabilitacao_id","proprioMorador_id":
						var f = (Reflect.field(m, field) == null) ? null : (Reflect.field(m, field) == 1);
						Reflect.setField(new_morador, field, f);
					//ctrl+c ctrl+v
					case "isEdited", "nomeMorador", "genero_id":
						Reflect.setField(new_morador, field, Reflect.field(m, field));
					case "date":
							var rawfield = Reflect.field(m, field);
							var x : HaxeTimestamp = rawfield == null ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
							Reflect.setField(new_morador, field, x);
					case "json":
						if (checkJson("Morador", Reflect.field(m, field)))
							Reflect.setField(new_morador, field, Reflect.field(m, field));
					case "gps_id","codigoReagendamento":
						continue;
					default:
						Macros.extraField("Morador", field);
				}
			}

			new_morador.syncTimestamp = curTimestamp;

			Macros.validateEntry(Morador, ["syncTimestamp", "id"], [ { key : "old_id", value : new_morador.old_id }, { key: "old_survey_id" , value : new_morador.old_survey_id } ], new_morador);

			morHash.set(new_morador.old_id , new_morador);
		}
		return false;
	}

	static function processPonto(session_id : Int, insertMode : Bool) : Bool
	{
		var dbPoints = targetCnx.request("SELECT * FROM Ponto WHERE session_id = " + session_id + " ORDER BY morador_id, ordem").results();
		for (p in dbPoints)
		{
			var new_point = new Ponto();
			for (field in Reflect.fields(p))
			{
				switch(field)
				{
					case "id":
						new_point.old_id = p.id;
					case "session_id":
						new_point.survey = sessHash.get(p.session_id);
						new_point.old_survey_id = p.session_id;
					case "morador_id":
						new_point.morador = morHash.get(p.morador_id);
					case "copiedFrom_id":
						new_point.copiedFrom = pointhash.get(p.id);
					case "pontoProximoRef_id":
						new_point.pontoProx = pointhash.get(p.pontoProxRef_id);
					case "isDeleted", "isPontoProx":
						new_point.isDeleted = (p.isDeleted == 1);
					//Static refs
					case "uf_id":
						new_point.uf = UF.manager.get(p.uf_id);
					case "ref_id":
						new_point.ref = Referencias.manager.get(p.ref_id);
					//ctrl+c ctrl+v
					case "isEdited", "city_id", "regadm_id", "street_id", "complement_id", "complement_two_id", "complement2_str", "ref_str", "tempo_saida", "tempo_chegada", "ordem":
						Reflect.setField(new_point, field, Reflect.field(p, field));
					case "date":
							var rawfield = Reflect.field(p, field);
							var x : HaxeTimestamp = rawfield == null ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
							Reflect.setField(new_point, field, x);
					case "json":
						if (checkJson("Ponto", Reflect.field(p, field)))
							Reflect.setField(new_point, field, Reflect.field(p, field));
					//Enums
					case "motivoID", "motivoOutraPessoaID":
						Macros.setEnumField("motivo", new_point, p, session_id);
					case "gps_id", "anterior_id", "posterior_id", "ordem", "city_str", "regadm_str", "street_str", "complement_str", "complement_two_str", "isIntermediario":
						continue;
					default:
						Macros.extraField("Ponto", field);
				}
			}

			new_point.syncTimestamp = curTimestamp;

			Macros.validateEntry(Ponto, [ "id", "syncTimestamp"], [ { key : "old_id", value : new_point.old_id } ], new_point);
			pointhash.set(new_point.old_id, new_point);
		}

		return false;
	}

	static function processModo(session_id : Int, insertMode : Bool)
	{
		var dbModos = targetCnx.request("SELECT * FROM Modo WHERE session_id = " + session_id + " ORDER BY morador_id, ordem").results();

		for (m in dbModos)
		{
			var new_modo = new Modo();
			for(f in Reflect.fields(m))
			{
				switch(f)
				{
					case "id":
						new_modo.old_id = m.id;
					case "session_id":
						new_modo.old_survey_id = m.session_id;
						new_modo.survey = sessHash.get(m.session_id);
					case "morador_id":
						new_modo.morador = morHash.get(m.morador_id);
						new_modo.old_morador_id = m.morador_id;
					case "firstpoint_id", "secondpoint_id":
						Reflect.setProperty(new_modo, f, (pointhash.get(Reflect.field(m, f)) != null) ? pointhash.get(Reflect.field(m, f)).id : null );
					//Enums
					case "meiotransporte_id":
						if (Macros.checkEnumValue(MeioTransporte, m.meiotransporte_id, session_id))
							new_modo.meiotransporte = Macros.getStaticEnum(MeioTransporte, m.meiotransporte_id);
					case "estacaoEmbarque_id", "estacaoDesembarque_id":
						Reflect.setProperty(new_modo, f.split("_")[0], EstacaoMetro.manager.get(Reflect.field(m, f)));
					case "linhaOnibus_id":
						new_modo.linhaOnibus = LinhaOnibus.manager.get(m.linhaOnibus_id);
					case "formaPagamento_id", "tipoEstacionamento_id":
						Macros.setEnumField(f, new_modo, m, session_id);
					//Bools
					case "isDeleted":
						new_modo.isDeleted = (m.isDeleted == 1);
					//Ctrl+c ctrl+v
					case "isEdited", "ordem", "linhaOnibus_str":
						Reflect.setField(new_modo, f, Reflect.field(m, f));
					case "date":
							var rawfield = Reflect.field(m, f);
							var x : HaxeTimestamp = rawfield == null ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
							Reflect.setField(new_modo, f, x);
					case "json":
						if (checkJson("Modo", Reflect.field(m, f)))
							Reflect.setField(new_modo, f, Reflect.field(m, f));
					//Conversoes de um mte de field pra um
					case "valorPagoTaxi", "valorViagem", "custoEstacionamento":
						new_modo.valorViagem = m.valorViagem;
					//fim conversao
					//Ignore
					case "anterior_id", "posterior_id","ordem", "gps_id", "estacaoEmbarque_str", "estacaoDesembarque_str","naoSabeLinhaOnibus", "naoSabeEstacaoEmbarque", "naoSabeEstacaoDesembarque", "naoSabeValorViagem", "naoSabeValorPagoTaxi", "naoSabeCustoEstacionamento","naoRespondeuLinhaOnibus", "naoRespondeuEstacaoEmbarque", "naoRespondeuEstacaoDesembarque", "naoRespondeuValorViagem", "naoRespondeuValorPagoTaxi","naoRespondeuCustoEstacionamento":
						continue;
					default:
						Macros.extraField("Modo", f);
				}
			}

			new_modo.syncTimestamp = curTimestamp;
			Macros.validateEntry(Modo, ["id", "syncTimestamp"], [ { key : "old_id" , value : new_modo.old_id } ], new_modo);
		}
		return false;
	}

	static function processOcorrencias(sid : Int, insertMode : Bool)
	{
		var res = targetCnx.request("SELECT * FROM Ocorrencias WHERE session_id = " + sid).results();
		for (r in res)
		{
			var c = new Ocorrencias();
			for (f in Reflect.fields(r))
			{
				switch(f)
				{
					case "id":
						c.old_id = r.id;
					case "session_id":
						c.survey = sessHash.get(r.session_id);
						c.old_survey_id = r.session_id;
					case "desc":
						Reflect.setField(c, f, Reflect.field(r, f));
					case "datetime":
							var rawfield = Reflect.field(r, f);
							var x : HaxeTimestamp = rawfield == null ? null : HaxeTimestamp.fromDate(Date.fromString(rawfield));
							Reflect.setField(c, f, x);
					case "json":
						if (checkJson("Ocorrencias", Reflect.field(r, f)))
							Reflect.setField(c, f, Reflect.field(r, f));
					case "sessionTime_id", "gps_id":
						continue;
					default:
						Macros.extraField("Ocorrencias", f);
				}
			}

			c.syncTimestamp = curTimestamp;
			Macros.validateEntry(Ocorrencias, ["id", "syncTimestamp"], [ { key : "old_id", value : c.old_id } ], c);
		}

		return false;

	}

	static function populateHash() : Map<String,Map<Int,Int>>
	{
		var t = new Map<String,Map<Int,Int>>();
		for (c in CompileTime.getAllClasses("common.spod", true, EnumTable))
		{
			var tempmap = new Map<Int,Int>();
			var res = (untyped c.manager : Manager<EnumTable>).all().map(function(v) { return [v.val, v.id]; } ).array();
			for (r in res)
			{
				tempmap.set(r[0], r[1]);
			}

			//Minha nomenclatura de tabelas estáticas é EnumName_Tbl
			var name = Type.getClassName(c).split("_")[0];
			t.set(name, tempmap);
		}

		return t;
	}
	

	static function ticket(subject : String, msg : String, survey_id : Int)
	{
		var survey = Survey.manager.get(survey_id);
		var t = new Ticket(survey, author, subject);
		t.insert();
		
		var sub = new TicketSubscription(t, group, null);
		sub.insert();
		
		var rec = new TicketRecipient(t, sub);
		rec.insert();
	}
	
	static function serverTimestamp()
	{
		var http = new Http("syncex.comtacti.com");
		http.setHeader("X-sync-type", "timestamp");
		http.onData = function(s : String)
		{
			var f = Std.parseFloat(s);
			var now = Date.now().getTime();
			//5s
			var dif = 5000;
			if (Math.abs(f - now) > dif)
			{
				throw "Error: Time difference is too damn high!";
			}
		}

		http.onError = function(e : Dynamic)
		{
			throw e;
		}
		http.request();

	}

	static function checkJson(table : String, str : String)
	{
		try
		{	if (str != null && str.length > 0)
			{
				var json = Json.parse(str);
				return json != null;
			}
			else
				return false;
		}
		catch (e : Dynamic)
		{
			Macros.criticalError(table, str + " is not a valid JSON!");
			return false;
		}
	}

}
