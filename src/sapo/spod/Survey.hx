package sapo.spod;

import common.db.MoreTypes;
import common.spod.EnumSPOD;
import common.spod.statics.EstacaoMetro;
import common.spod.statics.LinhaOnibus;
import common.spod.statics.Referencias;
import common.spod.statics.UF;
import sys.db.Object;
import sys.db.Types;

class Survey extends Object {
	public var id : SId;
	public var user_id : SInt; 
	public var userlogin : SString<255>; 
	public var tentativa_id : SNull<Int>;

	public var client_ip : SNull<SString<255>>;
	
	public var lastPageVisited : SNull<SString<255>>;
	public var isValid : SBool;
	
	/***********  SAPO FIELDS **********/
	public var paid : SNull<SBool> = false;
	public var paymentRef : SNull<SString<255>>;
	public var date_paid : SNull<HaxeTimestamp>;
	/***********************************/
	
	public var isRestored : SBool;
	public var dataInicioPesquisaPapel : SNull<HaxeTimestamp>; //
	public var dataFimPesquisaPapel : SNull<HaxeTimestamp>; //
	public var codigoFormularioPapel : SNull<SString<255>>; //
	
	public var date_create : HaxeTimestamp;
	public var date_started : SNull<HaxeTimestamp>; //
	public var date_finished : SNull<HaxeTimestamp>;
	public var date_completed : SNull<HaxeTimestamp>;	
	
	public var estadoPesquisa : SNull<SEnum<EstadoPesquisa>>;
	
	public var numReopenings : Null<SInt>;
	public var endereco_id : SNull<SInt>;
	public var pin : SNull<SString<255>>; //
	public var latitude : SNull<SFloat>;
	public var longitude : SNull<SFloat>;
	public var bairro : SNull<SString<255>>;
	public var logradouro : SNull<SString<255>>;
	public var numero : SNull<SString<255>>;
	public var complemento : SNull<SString<255>>;
	public var lote : SNull<SString<255>>;
	public var estrato : SNull<SString<255>>;
	public var json : Null<String>;

	/**   CHECKS -> Verificado?     **/
	public var checkSV : Null<Bool>;
	public var checkCT : Null<Bool>;
	public var checkCQ : Null<Bool>;
	public var isPhoned : Bool = false;
	public var group : Null<Int>;
	public var date_edited : Null<HaxeTimestamp>;
	/*********************************/

	public var old_survey_id : SInt;
	public var syncTimestamp : SFloat;

	override public function insert()
	{
		
		date_edited = Context.now;  // TODO this doesn't apply to sync, so shouldn't be here
		super.insert();
	}
}

class Ocorrencias extends Object {
	public var id : SId;
	//?
	public var desc : SNull<SString<4096>>; //
	@:relation(survey_id) public var survey : Survey;
	public var datetime : HaxeTimestamp;
	public var json : Null<String>;
	public var syncTimestamp : SFloat;
	public var old_id : SInt;
	public var old_survey_id : SInt;
}

class Familia extends Object {
	public var id : SId;
	@:relation(survey_id) public var survey : Survey;

	public var date : HaxeTimestamp;
	public var tentativa_id : SInt;
	public var isDeleted : SBool;
	public var isEdited : SInt;

	public var numeroResidentes : SNull<SInt>;
	public var ocupacaoDomicilio : SNull<SEnum<OcupacaoDomicilio>>;

	public var condicaoMoradia : SNull<SEnum<CondicaoMoradia>>;
	public var tipoImovel : SNull<SEnum<TipoImovel>>;

	public var banheiros : SNull<SInt>;
	public var quartos : SNull<SInt>;
	public var veiculos : SNull<SInt>;
	public var bicicletas : SNull<SInt>;
	public var motos : SNull<SInt>;

	public var aguaEncanada : SNull<SEnum<AguaEncanada>>;
	public var ruaPavimentada_id : SNull<SBool>;
	public var vagaPropriaEstacionamento_id : SNull<SBool>;
	public var anoVeiculoMaisRecente : SNull<SEnum<AnoVeiculoMaisRecente>>;
	public var empregadosDomesticos : SNull<SEnum<EmpregadosDomesticos>>;
	public var tvCabo_id : SNull<SBool>;


	public var nomeContato : SNull<SString<255>>;
	public var telefoneContato : SNull<SString<255>>;
	public var rendaDomiciliar : SNull<SEnum<RendaDomiciliar>>;
	public var recebeBolsaFamilia : SNull<SBool>;

	public var json : Null<String>;
	public var syncTimestamp : SFloat;
	public var old_id : SInt;
	public var old_survey_id : SInt;
}

class Morador extends Object {
	public var id : SId;

	@:relation(survey_id) public var survey : Survey;
	@:relation(familia_id) public var familia : Familia;
	public var date : HaxeTimestamp;
	public var isDeleted : SBool;
	public var isEdited : SInt;

	public var nomeMorador : SNull<SString<255>>;
	public var proprioMorador_id : SNull<SBool>;
	public var idade : SNull<SEnum<Idade>>;
	public var genero_id : SNull<SInt>;
	public var grauInstrucao : SNull<SEnum<GrauInstrucao>>;
	@:relation(quemResponde_id) public var quemResponde : SNull<Morador>;

	public var situacaoFamiliar : SNull<SEnum<SituacaoFamiliar>>;
	public var atividadeMorador : SNull<SEnum<AtividadeMorador>>;
	public var possuiHabilitacao_id : SNull<SBool>;
	public var portadorNecessidadesEspeciais : SNull<SEnum<PortadorNecessidadesEspeciais>>;
	
	public var setorAtividadeEmpresaPrivada : SNull<SEnum<SetorAtividadeEmpresaPrivada>>;
	public var setorAtividadeEmpresaPublica : SNull<SEnum<SetorAtividadeEmpresaPublica>>;

	public var motivoSemViagem : SNull<SEnum<MotivoSemViagem>>;
	public var json : Null<String>;
	public var syncTimestamp : SFloat;
	public var old_id : SInt;
	public var old_survey_id : SInt;
}

class Ponto extends Object {
	public var id : SId;

	@:relation(survey_id) public var survey : Survey;
	@:relation(morador_id) public var morador : Morador;

	public var date : HaxeTimestamp;

	public var isEdited : SInt;
	public var isDeleted : SBool;
	
	public var ordem : SInt;

	@:relation(uf_id) public var uf : UF;
	public var city_id : SInt;
	public var regadm_id : SNull<SInt>;
	public var street_id : SNull<SInt>;
	public var complement_id : SNull<SInt>;
	public var complement_two_id : SNull<SInt>;
	public var complement2_str : SNull<SString<255>>;
	@:relation(ref_id) public var ref : SNull<Referencias>;
	public var ref_str : SNull<SString<255>>;

	public var motivo : SNull<SEnum<Motivo>>;
	public var motivoOutraPessoa : SNull<SEnum<Motivo>>;
	public var tempo_saida : SNull<SString<255>>;
	public var tempo_chegada : SNull<SString<255>>;
	public var json : Null<String>;

	@:relation(copiedFrom_id) public var copiedFrom : SNull<Ponto>;
	public var isPontoProximo : SNull<SBool>;
	@:relation(pontoProx_id) public var pontoProx : SNull<Ponto>;
	public var old_id : SInt;
	public var syncTimestamp : SFloat;
	public var old_survey_id : SInt;
}

class Modo extends Object {
	public var id : SId;

	@:relation(survey_id) public var survey : Survey;

	@:relation(morador_id) public var morador : Morador;

	@:relation(firstpoint_id) public var firstpoint : Ponto;
	@:relation(secondpoint_id) public var secondpoint : Ponto;
	public var ordem : Int;
	public var date : HaxeTimestamp;

	public var isEdited : SInt;
	public var isDeleted : SBool;

	public var meiotransporte : SEnum<MeioTransporte>;

	@:relation(linhaOnibus_id) public var linhaOnibus : SNull<LinhaOnibus>;
	public var linhaOnibus_str : SNull<SString<255>>;
	@:relation(estacaoEmbarque_id) public var estacaoEmbarque : SNull<EstacaoMetro>;

	@:relation(estacaoDesembarque_id) public var estacaoDesembarque : SNull<EstacaoMetro>;

	public var formaPagamento : SNull<SEnum<FormaPagamento>>;
	public var tipoEstacionamento : SNull<SEnum<TipoEstacionamento>>;

	// Coisas resumidas:

	public var valorViagem : SNull<SFloat>;
	
	public var json : Null<String>;

	public var syncTimestamp : SFloat;
	public var old_survey_id : SInt;
	public var old_morador_id : SInt;
	public var old_id : SInt;
}

@:id(user_id, group)
class SurveyGroupStatus extends Object
{
	public var user_id : SInt;
	//Group number
	public var group : SInt;
	//Surveys in this group
	public var pesqGrupo : SInt;
	
	//Checks por grupo ( MIN(survey.checkFOO) )
	public var checkSV : SNull<SBool>;
	public var checkCT : SNull<SBool>;
	public var checkCQ : SNull<SBool>;
	
	//Status de grupo (Summary)
	public var Completa : SNull<SBool>;
	public var allFalse : SInt;
	public var hasFalse : SInt;
	public var isTrue : SInt;
	
	public override function insert()
	{
		throw ("NO INSERT QUERIES ALLOWED! THIS IS A VIEW!");
	}
	
	public override function update()
	{
		throw ("NO UPDATE QUERIES ALLOWED! THIS IS A VIEW!");
	}
	
	public override function lock()
	{
		throw("You can't lock a view!");
	}
}

@:id(id)
class SurveyCheckStatus extends Object
{
	//id -> Survey.id
	public var id : SInt;
	public var group : SInt;
	public var isPhoned : SBool;
	
	//Checks per group if Survey.checkFOO is null
	public var checkSV : SNull<SBool>;
	public var checkCT : SNull<SBool>;
	public var checkCQ : SNull<SBool>;
	
	public override function insert()
	{
		throw ("NO INSERT QUERIES ALLOWED! THIS IS A VIEW!");
	}
	
	public override function update()
	{
		throw ("NO UPDATE QUERIES ALLOWED! THIS IS A VIEW!");
	}
	
	public override function lock()
	{
		throw("You can't lock a view!");
	}
	
	
}

