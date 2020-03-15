#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} COMRD004
//TODO Descrição Envia WorkFlow de Aprovacao de Solicitacao de Compras.
	@author Igor Silva
	@since 11/03/2020
	@version 1.0
	@return ${return}, ${return_description}

	@type function
/*/
User Function COMRD004()

Local cSuperior := PswRet()[1][11]
Local cTotItem := Strzero(Len(aCols),4)

Private cDiasA
Private cDiasE

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



If ! Empty(cSuperior)
	
	RecLock("SC1",.F.)
		C1_CODAPRO := cSuperior
	MsUnlock()
	
	U_COMWF005(cSuperior)
	
EndIf

Return