package common.spod;
import haxe.Template;
import sys.db.Object;
import sys.db.Types.SEnum;
import sys.db.Types.SId;
import sys.db.Types.SInt;
import sys.db.Types.SNull;
import sys.db.Types.SString;

/**
 * ...
 * @author Caio
 */
 
 class EnumTable extends Object
 {
	public var id : SId;
	public var val : SNull<SInt>;
	public var name : SString<255>;
 }
 
 //Classes de Relação com id/desc apenas
 @dbNullVal(0) @tt("Recebe Água Encanada?") enum AguaEncanada {
	@dbVal(1) @tt("possui água encanada em pelo menos em um cômodo") Sim;
	@dbVal(2) @tt("possui água encanada em na propriedade")  SimPropriedade;
	@dbVal(3) @tt("não possui água encanada")  Nao;
 }
 class AguaEncanada_Tbl extends EnumTable { }

 @dbNullVal(101) @tempstring("Veículo:") enum AnoVeiculoMaisRecente {
	@dbVal(1) @tt("posterior a 2014") Mais2014;
	@dbVal(2) @tt("de 2010 a 2013") De2010;
	@dbVal(3) @tt("de 2005 a 2009") De2005;
	@dbVal(4) @tt("de 2000 a 2004") De2000;
	@dbVal(5) @tt("de 1995 a 1999") De1995;
	@dbVal(6) @tt("de 1990 a 1994") De1990;
	@dbVal(7) @tt("anterior a 1989") De1989;
	@dbVal(90) @tt("não sabe") NaoSabe;
	@dbVal(101) @tt("não respondeu") NaoRespondeu;
 }
 class AnoVeiculoMaisRecente_Tbl extends EnumTable { }

  
@dbNullVal(101) @tt("Principal Atividade:")enum AtividadeMorador
{
	@dbVal(1)@tt("Empregado de empresa privada")  EmpresaPrivada;
	@dbVal(2) @tt("Funcionário público") Publico;
	@dbVal(3) @tt("Profissional liberal") Liberal;
	@dbVal(4) @tt("Empresário") Empresario;
	@dbVal(5) @tt("Trabalho informal") Informal;
	@dbVal(6) @tt("Empregado doméstico") Domestico;
	@dbVal(7) @tt("Voluntário") Voluntario;
	@dbVal(8) @tt("Cuidar do próprio lar") Lar;
	@dbVal(9) @tt("Aposentado") Aposentado;
	@dbVal(10) @tt("Desempregado") Desempregado;
	@dbVal(11) @tt("Estudante regular") EstudanteRegular;
	@dbVal(12) @tt("Estudante outros") EstudanteOutros;
	@dbVal(13) @tt("Não tem") NaoTem;
	@dbVal(99) @tt("Outra") Outros;
	@dbVal(101) @tt("Não respondeu") NaoRespondeu;
 }
 class AtividadeMorador_Tbl extends EnumTable{ }
	
 @dbNullVal(101) @tt("Moradia:") enum CondicaoMoradia {
	@dbVal(1) @tt("moradia próprio") Propria;
	@dbVal(2) @tt("moradia própria, em aquisição") PropriaAquisicao;
	@dbVal(3) @tt("moradia alugada") Alugada;
	@dbVal(4) @tt("moradia cedida") Cedida;
	@dbVal(5) @tt("moradia funcional") Funcional;
	@dbVal(6) @tt("moradia sob concessão de uso") ConcessaoUso;
	@dbVal(99) @tt("condição de moradia outra") Outros;
	@dbVal(101) @tt("não respondeu sobre a condição de moradia") NaoRespondeu;
 }
 class CondicaoMoradia_Tbl extends EnumTable{ }
 
  @dbNullVal(5) @tt("Empregados Doméstico:") enum EmpregadosDomesticos {
	@dbVal(1) @tt("empregado doméstico residente") Residente;
	@dbVal(2) @tt("empregado doméstico mensalista") Mensalista;
	@dbVal(3) @tt("empregado doméstico diarista") Diarista;
	@dbVal(4) @tt("não possui empregado doméstico") NaoPossui;
	@dbVal(5) @tt("não respondeu se possui empregado doméstico") NaoRespondeu;
 }
 class EmpregadosDomesticos_Tbl extends EnumTable { }
   

 @dbNullVal(0) @tt("Status da Pesquisa:") enum EstadoPesquisa {
	@dbVal(1) @tt("Concluída") Concluida;
	@dbVal(2) @tt("Incompleta, falta entrevistar morador") IncompletaMorador;
	@dbVal(3) @tt("Incompleta, falta registrar viagem") IncompletaViagem;
 }
 class EstadoPesquisa_Tbl extends EnumTable { }

 
  @dbNullVal(101) @tt("Forma de Pagamento") enum FormaPagamento {
	@dbVal(1) @tt("pagto: dinheiro") Dinheiro;
	@dbVal(2) @tt("pagto: cartão") Cartao;
	@dbVal(3) @tt("pagto: VT") VT;
	@dbVal(4) @tt("pagto: estudante") Estudante;
	@dbVal(10) @tt("pagto: gratuidade") Gratuidade;
	@dbVal(99) @tt("pagto: outros") Outros;
	@dbVal(101) @tt("pagto: não respondeu") NaoRespondeu;
 }
 class FormaPagamento_Tbl extends EnumTable { }
  @dbNullVal(8) @tt("Frequência  com que faz a viagem:") enum FrequenciaViagem {
	@dbVal(1) @tt("Raramente") Raramente;
	@dbVal(2) @tt("Menos de 1 vez por mês") Menos1Mes;
	@dbVal(3) @tt("Até 1 vez por mês") Vez1Mes;
	@dbVal(4) @tt("Até 2 vezes por mês") Vez2Mes;
	@dbVal(5) @tt("De 1 a 2 vezes por semana") Semana1a2;
	@dbVal(6) @tt("De 3 a 4 vezes por semana") Semana3a4;
	@dbVal(7) @tt("Mais de 5 vezes por semana") MaisSemana5;
	@dbVal(8) @tt("Não Respondeu") NaoRespondeu;
 }
 class FrequenciaViagem_Tbl extends EnumTable { }

 
  @dbNullVal(99) enum GrauInstrucao {
	 @dbVal(1) @tt("Analfabeto") Analfabeto;
	 @dbVal(2) @tt("Alfabetizado") Alfabetizado;
	 @dbVal(3) @tt("Pré-Escolar") PreEscolar;
	 @dbVal(4) @tt("Fundamental incompleto") FundamentalIncompleto;
	 @dbVal(5) @tt("Fundamental completo") FundamentalCompleto;
	 @dbVal(6) @tt("Ensino médio incompleto") MedioIncompleto;
	 @dbVal(7) @tt("Ensino médio Completo") MedioCompleto;
	 @dbVal(8) @tt("Superior incompleto") SuperiorIncompleto;
	 @dbVal(9) @tt("Superior completo") SuperiorCompleto;
	 @dbVal(10) @tt("Pós-graduação") Pos;
	 @dbVal(11) @tt("Não estuda") NaoEstuda;
	 @dbVal(99) @tt("Não respondeu") NaoRespondeu;
 }
 class GrauInstrucao_Tbl extends EnumTable { }
 
  @dbNullVal(101) @tt("Idade") enum Idade
 {
	@dbVal(1) @tt("0 - 4") De00Ate04;
	@dbVal(2) @tt("5 - 9") De05Ate09;
	@dbVal(3) @tt("10 - 14") De10Ate14;
	@dbVal(4) @tt("15 - 17") De15Ate17;
	@dbVal(5) @tt("18 - 19") De18Ate19;
	@dbVal(6) @tt("20 - 24") De20Ate24;
	@dbVal(7) @tt("25 - 29") De25Ate29;
	@dbVal(8) @tt("30 - 39") De30Ate39;
	@dbVal(9) @tt("40 - 49") De40Ate49;
	@dbVal(10) @tt("50 - 59") De50Ate59;
	@dbVal(11) @tt("60 - 69") De60Ate69;
	@dbVal(12) @tt("70 - 79") De70Ate79;
	@dbVal(13) @tt("80 - 120") Mais80;
	@dbVal(101) @tt("Idade não informada") NaoRespondeu;
 }
 class Idade_Tbl extends EnumTable { }

  @dbNullVal(0) @tt("Meio de Transporte") enum MeioTransporte{
	 @dbVal(1) @tt("A pé") Ape;
	 @dbVal(2) @tt("Bicicleta") Bicicleta;
	 @dbVal(3) @tt("Ônibus convencional") OnibusConv;
	 @dbVal(4) @tt("BRT") BRT;
	 @dbVal(5) @tt("Ônibus escolar") Escolar;
	 @dbVal(6) @tt("Ônibus fretado") Fretado;
	 @dbVal(7) @tt("Ônibus clandestino") Clandestino;
	 @dbVal(8) @tt("Metrô") Metro;
	 @dbVal(9) @tt("Automóvel - condutor") AutoCond;
	 @dbVal(10) @tt("Automóvel - passageiro") AutoPass;
	 @dbVal(11) @tt("Motocicleta - condutor") MotoCond;
	 @dbVal(12) @tt("Motocicleta - passageiro") MotoPass;
	 @dbVal(13) @tt("Táxi") Taxi;
	 @dbVal(14) @tt("Motorista privado") MotoristaPrivado;
	 @dbVal(15) @tt("Moto-taxi") MotoTaxi;
	 @dbVal(99) @tt("Outros") Outros;
 }
 class MeioTransporte_Tbl extends EnumTable { }
 
  @dbNullVal(101) @tt("Motivo da viagem:") enum Motivo
 {
	@dbVal(1) @tt("Residência") Residencia;
	@dbVal(2) @tt("Trabalho principal") TrabPrincipal;
	@dbVal(3) @tt("Trabalho secundário") TrabSecundario;
	@dbVal(4) @tt("Negócios") Negocios;
	@dbVal(5) @tt("Estudo regular") EstudoReg;
	@dbVal(6) @tt("Estudo outros") EstudoSec;
	@dbVal(7) @tt("Compras") Compras;
	@dbVal(8) @tt("Pessoais") Pessoais;
	@dbVal(9) @tt("Refeição") Refeicao;
	@dbVal(10) @tt("Saúde") Saude;
	@dbVal(11) @tt("Lazer") Lazer;
	@dbVal(12) @tt("Levar outra pessoa") LevarPessoa;
	@dbVal(99) @tt("Outro motivo") Outros;
	@dbVal(101) @tt("Não respondeu o motivo") NaoRespondeu;
 }
 class Motivo_Tbl extends EnumTable { }

 //TODO
 @dbNullVal(3) @tt("Motivo sem viagens:") enum MotivoSemViagem
 {
	@dbVal(1) @tt("Não realizou") NaoRealizou;
	@dbVal(2) @tt("Nao sabe") NaoSoube;
	@dbVal(3) @tt("Não respondeu") NaoRespondeu;
 }
 class MotivoSemViagem_Tbl extends EnumTable { }
 
 @dbNullVal(0) @tt("Ocupacao Domicílio") enum OcupacaoDomicilio
 {
	@dbVal(1) @tt("Unifamiliar")  Uni;
	@dbVal(2) @tt("Multifamiliar") Multi;
	@dbVal(3) @tt("República") Republica;
	@dbVal(4) @tt("Compartilhado") Compartilhado;
	@dbVal(99) @tt("Outros") Outros;
 }
 class OcupacaoDomicilio_Tbl extends EnumTable { }

 @dbNullVal(0) @tt("Portador de Necessidades Especiais") enum PortadorNecessidadesEspeciais
 {
	@dbVal(1) @tt("Não") NaoAplica;
	@dbVal(2) @tt("Cognitiva") Cognitiva;
	@dbVal(3) @tt("Cegueira") Cegueira;
	@dbVal(4) @tt("Fisica temporária") FisicaTemp;
	@dbVal(5) @tt("Fisica permanente") FisicaPerm;
	@dbVal(6) @tt("Cadeirante") Cadeirante;
	@dbVal(7) @tt("Outra(s)") Outros;
 }
 class PortadorNecessidadesEspeciais_Tbl extends EnumTable { }
 
 @dbNullVal(101) @tt("Setor de Atividade em Empresa Privada") enum SetorAtividadeEmpresaPrivada
 {
	 @dbVal(1) @tt("Agropecuária")  Agropecuaria;
	 @dbVal(2) @tt("Construção civil") ConstrucaoCivil;
	 @dbVal(3) @tt("Indústria") Industria;
	 @dbVal(4) @tt("Comércio") Comercio;
	 @dbVal(5) @tt("Financeiro") Financeiro;
	 @dbVal(6) @tt("Serviços") Servicos;
	 @dbVal(99) @tt("Outro") Outro;
	 @dbVal(101) @tt("Não respondeu") NR;
 }
 class SetorAtividadeEmpresaPrivada_Tbl extends EnumTable { }
 
 @dbNullVal(101) @tt("Setor de Atividade em Empresa Pública") enum SetorAtividadeEmpresaPublica {
	@dbVal(1) @tt("Administração federal") AdministracaoFederal;
	@dbVal(2) @tt("Administração GDF") AdministracaoGDF;
	@dbVal(3) @tt("Administração municipal") AdministracaoMunicipal;
	@dbVal(101) @tt("Não respondeu") NR;
 }
 class SetorAtividadeEmpresaPublica_Tbl extends EnumTable { }
 
 @dbNullVal(13) @tt("Renda Domiciliar") enum RendaDomiciliar
 {
	@dbVal(1) @tt("Sem Renda") Sem;
	@dbVal(2) @tt("Acima de 0 e até 440 reais ") De0;
	@dbVal(3) @tt("Acima de 440 reais e até 880 reais") De440;
	@dbVal(4) @tt("Acima de 880 reais e até 1.760 reais") De880;
	@dbVal(5) @tt("Acima de 1.760 reais e até 2.640 reais") De1760;
	@dbVal(6) @tt("Acima de 2.640 reais e até 4.400 reais") De2640;
	@dbVal(7) @tt("Acima de 4.400 reais e até 8.800 reais") De4400;
	@dbVal(8) @tt("Acima de 8.800 reais e até 13.200 reais") De8800;
	@dbVal(9) @tt("Acima de 13.200 reais e até 17.600 reais") De13200;
	@dbVal(10) @tt("Acima de 17.600 reais e até 22.000 reais") De17600;
	@dbVal(11) @tt("Acima de 22.000 reais e até 26.400 reais") De22000;
	@dbVal(12) @tt("Acima de 26.400 reais") De26400;	
	@dbVal(13) @tt("Não respondeu") NaoRespondeu;
 }
  class RendaDomiciliar_Tbl extends EnumTable { }
 
 @dbNullVal(0) @tt("Situação Familiar") enum SituacaoFamiliar
 {
	@dbVal(1) @tt("Responsável") Responsavel;
	@dbVal(2) @tt("Cônjuge") Conjuge;
	@dbVal(3) @tt("Filho(a)") Filho;
	@dbVal(4) @tt("Pai/Mãe/Sogro(a)") Pai;
	@dbVal(5) @tt("Parente") Parente;
	@dbVal(6) @tt("Pensionista") Pensionista;
	@dbVal(7) @tt("Agregado") Agregado;
	@dbVal(8) @tt("Empregado residente") EmpregadoResidente;
	@dbVal(9) @tt("Residente temporário") ResidenteTemp;
	@dbVal(99) @tt("Outros") Outros;
 }
 class SituacaoFamiliar_Tbl extends EnumTable { }
 
 @dbNullVal(101) @tt("Tipo de Estacionamento") enum TipoEstacionamento
 {
    @dbVal(2) @tt("estacionamento gratuito na via pública") GratuitoViaPublica;
    @dbVal(1) @tt("estacionamento próprio") Propria;
	@dbVal(3) @tt("estacionamento gratuíto fora da via pública") GratuitoFora;
	@dbVal(4) @tt("estacionamento pago mensal") EstPagoMensal;
	@dbVal(5) @tt("estacionamento pago por hora") EstPagoHora;
	@dbVal(6) @tt("não estacionou") NaoEstacionou;
	@dbVal(99) @tt("estacionamento outro") Outros;
	@dbVal(101) @tt("não respondeu sobre estacionamento") NaoRespondeu;
 }
 class TipoEstacionamento_Tbl extends EnumTable { }

 @dbNullVal(9) @tt("Tempo de Permanência no Estacionamento:") enum TempoPermanenciaEstacionamento {
	 @dbVal(1) @tt("Meia hora") MeiaHora;
	 @dbVal(2) @tt("Uma hora") UmaHora;
	 @dbVal(3) @tt("Duas horas") DuasHoras;
	 @dbVal(4) @tt("Um turno") Turno;
	 @dbVal(5) @tt("Um dia") Diaria;
	 @dbVal(6) @tt("Pernoite") Pernoite;
	 @dbVal(7) @tt("Mais de um dia") MaisDeUmDia;
	 @dbVal(8) @tt("Não Sabe") NaoSabe;
	 @dbVal(9) @tt("Não Respondeu") NaoRespondeu;
 }
 class TempoPermanenciaEstacionamento_Tbl extends EnumTable { }

 @dbNullVal(0) @tt("Tipo de Imóvel") enum TipoImovel
 {
	 @dbVal(1) @tt("Apartamento")  Apartamento;
	 @dbVal(2) @tt("Casa de alvenaria acabada") CasaAlvenaria;
	 @dbVal(3) @tt("Casa de alvenaria inacabada") AlvenariaInacabada;
	 @dbVal(4) @tt("Barraco com piso") BarracoComPiso;
	 @dbVal(5) @tt("Barraco sem piso") BarracoSemPiso;
	 @dbVal(6) @tt("Prédio comercial") PredioComercial;
	 @dbVal(99) @tt("Outros") Outros;
 }
  class TipoImovel_Tbl extends EnumTable { }
 
 
 
