#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} COMRD003
//TODO Descrição Envia WorkFlow de Aprovacao de Solicitacao de Compras.
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return ${return}, ${return_description}

	@type function

	@obs Necessario Criar Campo
	@param Nome: C1_CODAPRO		
	@param Tipo: C	
	@param Tamanho: 6		
	@param Titulo: Cod Aprovador  

	@link https://interno.totvs.com/mktfiles/tdiportais/helponlineprotheus/p12/portuguese/sigaworkflow_workflow_via_http_exemplo.htm 		
/*/
User Function COMRD003()

Local cSuperior := PswRet()[1][11]
Local cTotItem := Strzero(Len(aCols),4)

Private cDiasA
Private cDiasE
Private cPerg  := Padr("COMRD3",10)

//GRAVA O NOME DA FUNCAO NA Z03
//U_CFGRD001(FunName())

//***********************************************
//	Verifica a Existencia de Parametro MV__TIMESC
//	Caso nao exista. Cria o parametro.           
//***********************************************
dbSelectArea("SX6")
If ! dbSeek("  "+"MV__TIMESC")
	RecLock("SX6",.T.)
	X6_VAR    	:= "MV__TIMESC"
	X6_TIPO 	:= "C"
	X6_CONTEUD 	:= "0305"
	X6_CONTENG 	:= "0305"
	X6_CONTSPA 	:= "0305"
	X6_DESCRIC	:= "DEFINE TEMPO EM DIAS DE TIMEOUT DA APROVACAO DE SO"
	X6_DESC1	:= "LICITACAO DE COMPRAS - EX: AVISO EM 3 DIAS E EXCLU"
	X6_DESC2	:= "SAO EM 5 DIAS = 0305                              "
	MsUnlock("SX6")
EndIf

cDiasA := SubStr(GetMv("MV__TIMESC"),1,2) //TIMEOUT Dias para Avisar Aprovador
cDiasE := SubStr(GetMv("MV__TIMESC"),3,2) //TIMEOUT Dias para Excluir a Solicitacao

/*Não vi necessidade de chamar o pergunte. Os parametros não 
influenciam no restante do processo. Também não há necessidade de chamar
a função U_COMWF002, visto que, a rotina U_COMWF001 faz o envio e tratativos do 
WorkFlow*/

//Pergunte(cPerg,.T.) //Carrega Perguntas

If ! Empty(cSuperior)
	
	RecLock("SC1",.F.)
		C1_CODAPRO := cSuperior
	MsUnlock()



	U_COMWF001(cSuperior)
	
	
	/*If mv_par04 == 1 				//Aprovacao por ITEM
		U_COMWF002()
	ElseIf SC1->C1_ITEM == cTotItem //Aprovacao por SOLICITACAO
		U_COMWF001(cSuperior)
	EndIf

	
	U_COMWF002() //Envio dos Detalhes da Solicitacao
	
	If SC1->C1_ITEM == cTotItem
		U_COMWF001(cSuperior) //Envido do Resumo da Solicitacao
	EndIf
	*/
	
EndIf

Return