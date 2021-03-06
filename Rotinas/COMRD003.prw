#include 'protheus.ch'
#include 'parmtype.ch'

//====================================================================================================================\\
/*/{Protheus.doc} COMRD003
  ======================================================================================================================
	@description
	Envia WorkFlow de Aprovacao de Solicitacao de Compras.
	
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return
	@type function

	@obs Necessario Criar Campo
	@param Nome: C1_CODAPRO		
	@param Tipo: C	
	@param Tamanho: 6		
	@param Titulo: Cod Aprovador 
	
	@obs Necessario criar Campo C1_SPORTAL para ser gravado se a Sc de compra foi pelo portal ou n�o,
	.T. para sim e .F. para n�o.
	@param Nome: C1_SPORTAL	
	@param Tipo: L	
	@param Tamanho: 1		
	@param Titulo: Sc Portal
	
	@obs Necessario criar Campo C1_WFENVIO para ser gravado se o WF foi enviado  ou n�o,
	.T. para sim e .F. para n�o.
	@param Nome: C1_WFENVIO	
	@param Tipo: L	
	@param Tamanho: 1		
	@param Titulo: WF Envio	
	
	@obs Necessario Criar tabela ZZA (Grupo de aprova��o de sol. de compra)
	@param ZZA_NUM  C 6		
	@param ZZA_CODGRP C 6
	@param ZZA_APROV C 6		
	@param ZZA_USER C 6
	@param ZZA_NIVEL C 2
	@param ZZA_STATUS C 6
	@param ZZA_DTLIB D

	@link https://interno.totvs.com/mktfiles/tdiportais/helponlineprotheus/p12/portuguese/sigaworkflow_workflow_via_http_exemplo.htm 		
/*/
//====================================================================================================================\\
User Function COMRD003()

	Local aArea		:= GetArea()
	Local aAreaSX6	:= GetArea()
	Local cSuperior := ""
	Local cTotItem 	:= Strzero(Len(aCols),4)
	Local cNumSc 	:= SC1->C1_NUM
	Local cStatus 	:= "01" //Status = 01 aguardando aprova��o | 02 aprovado | 03 rejeitado
	Local cAliasSAL	:= ""
	Local cQuerySAL := ""
	Local aSAL 		:= {}
	Local nSAL 		:= 0

	Private cDiasA 	:= ""
	Private cDiasE	:= ""
	//Private cPerg := Padr("COMRD3",10)

	//***********************************************
	//	Verifica a Existencia de Parametro MV__TIMESC
	//	Caso nao exista. Cria o parametro.
	//***********************************************
	DbSelectArea("SX6")
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
	SX6->(DbCloseArea())

	//cDiasA := SubStr(GetMv("MV__TIMESC"),1,2) //TIMEOUT Dias para Avisar Aprovador
	//cDiasE := SubStr(GetMv("MV__TIMESC"),3,2) //TIMEOUT Dias para Excluir a Solicitacao

	//Pergunte(cPerg,.T.) //Carrega Perguntas

	//Consulta grupo de aprovadores
	cAliasSAL := GetNextAlias()
	cQuerySAL := " SELECT AL_COD, AL_APROV, AL_USER, AL_NIVEL "
	cQuerySAL += " FROM " + RetSqlName("SAL")  + " SAL "
	cQuerySAL += " WHERE D_E_L_E_T_ <> '*' "
	cQuerySAL := ChangeQuery(cQuerySAL)

	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuerySAL), cAliasSAL, .F., .T.)

	//Array com grupo de aprovadores
	While (cAliasSAL)->(!Eof())
		AADD( aSAL,{ (cAliasSAL)->AL_COD,	;	//1 - C�d. grupo de aprova��o
		(cAliasSAL)->AL_APROV,	;	//2 - C�d. aprovador
		(cAliasSAL)->AL_USER,	;	//3 - C�d. usu�rio
		(cAliasSAL)->AL_NIVEL} )  	//4 - N�vel
		(cAliasSAL)->(DbSkip())
	EndDo

	//Grava ZZA - Grupo de aprova��o de SC
	For nSAL := 1 To Len(aSAL)
		If RecLock("ZZA", .T.)
			ZZA->ZZA_FILIAL 	:= FWxFilial('ZZA')
			ZZA->ZZA_NUM    	:= AllTrim( cNumSc ) 			//Num Doc
			ZZA->ZZA_CODGRP		:= AllTrim( aSAL[nSAL,1] )		//Cod. Grupo Aprova��o
			ZZA->ZZA_APROV		:= AllTrim( aSAL[nSAL,2] )		//Cod. Aprovador
			ZZA->ZZA_USER   	:= AllTrim( aSAL[nSAL,3] )		//Cod. Usu�rio
			ZZA->ZZA_NIVEL  	:= AllTrim( aSAL[nSAL,4] )		//N�vel de aprova��o
			ZZA->ZZA_STATUS		:= AllTrim( cStatus )			//Status = 01 aguardando aprova��o | 02 aprovado | 03 rejeitado
			//ZZA->ZZA_DTLIB 		:= " "				//Data da libera��o
			ZZA->(MsUnLock()) // Confirma e finaliza a opera��o
		Else
			MsgStop("N�o foi poss�vel travar o registro para manipula��o!", "Aten��o")
		EndIf
	Next nSAL

	RestArea(aArea)
	RestArea(aAreaSX6)
Return
// FIM da Funcao COMRD003
//======================================================================================================================


//======================================================================================================================
/*/{Protheus.doc} COMWF001
  ======================================================================================================================
	@description
	Envia Workflow de Aprovacao de Solicitacao de Compras.
	Para quando a aprovacao e feita por SOLICITACAO.
	
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return 
	@param cAprov
	@type function
/*/
//======================================================================================================================
User Function COMWF001(cAprov)

	Local cMvAtt 	:= GetMv("MV_WFHTML")
	Local cMailSup 	:= UsrRetMail(cAprov)
	Local cMailId	:= ""							//ID do processo gerado.
	Local cHostWF	:= "http://localhost:91/wf"		//URL configurado no ini para WF Link.

	Local oHtml

	cQuery := " SELECT C1_NUM, C1_EMISSAO, C1_SOLICIT, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_DATPRF, C1_OBS, C1_CC, C1_CODAPRO, C1_USER"
	cQuery += " FROM " + RetSqlName("SC1")
	cQuery += " WHERE C1_NUM = '"+SC1->C1_NUM+"'"

	MemoWrit("COMWF001.sql",cQuery)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

	TcSetField("TRB","C1_EMISSAO","D")
	TcSetField("TRB","C1_DATPRF","D")

	COUNT TO nRec

	//CASO TENHA DADOS
	If nRec > 0
		dbSelectArea("TRB")
		dbGoTop()

		cNumSc		:= TRB->C1_NUM
		cSolicit	:= TRB->C1_SOLICIT
		dDtEmissao	:= DTOC(TRB->C1_EMISSAO)

		//*****************************************************
		//	Muda o parametro para enviar no corpo do e-mail
		//*****************************************************
		PutMv("MV_WFHTML","T")

		oProcess := TWFProcess():New("000004","WORKFLOW PARA APROVACAO DE SC")
		oProcess:NewTask('Inicio',"\workflow\koala\COMWF001.htm")
		oHtml   := oProcess:oHtml

		oHtml:ValByName("diasA"			, cDiasA)
		oHtml:ValByName("diasE"			, cDiasE)
		oHtml:ValByName("cNUM"			, TRB->C1_NUM)
		oHtml:ValByName("cEMISSAO"		, DTOC(TRB->C1_EMISSAO))
		oHtml:ValByName("cSOLICIT"		, TRB->C1_SOLICIT)
		oHtml:ValByName("cCODUSR"		, TRB->C1_USER)
		oHtml:ValByName("cAPROV"		, "")
		oHtml:ValByName("cMOTIVO"		, "")
		oHtml:ValByName("it.ITEM"		, {})
		oHtml:ValByName("it.PRODUTO"	, {})
		oHtml:ValByName("it.DESCRI"		, {})
		oHtml:ValByName("it.UM"			, {})
		oHtml:ValByName("it.QUANT"		, {})
		oHtml:ValByName("it.DATPRF"		, {})
		oHtml:ValByName("it.OBS"		, {})
		oHtml:ValByName("it.CC"			, {})

		dbSelectArea("TRB")
		dbGoTop()

		While !EOF()
			aadd(oHtml:ValByName("it.ITEM")       ,TRB->C1_ITEM			) //Item Cotacao
			aadd(oHtml:ValByName("it.PRODUTO")    ,TRB->C1_PRODUTO		) //Cod Produto
			aadd(oHtml:ValByName("it.DESCRI")     ,TRB->C1_DESCRI		) //Descricao Produto
			aadd(oHtml:ValByName("it.UM")         ,TRB->C1_UM			) //Unidade Medida
			aadd(oHtml:ValByName("it.QUANT")      ,TRANSFORM( TRB->C1_QUANT,'@E 999,999.99' )) //Quantidade Solicitada
			aadd(oHtml:ValByName("it.DATPRF")     ,DTOC(TRB->C1_DATPRF)) //Data da Necessidade
			aadd(oHtml:ValByName("it.OBS")        ,TRB->C1_OBS			) //Observacao
			aadd(oHtml:ValByName("it.CC")         ,TRB->C1_CC			) //Centro de Custo
			dbSkip()
		EndDo

		//envia o e-mail
		cUser 				:= Subs(cUsuario,7,15)
		oProcess:ClientName(cUser)
		oProcess:cTo    	:= "koala"
		oProcess:cSubject  	:= "E-mail para aprova��o de SC - "+cNumSc+" - De: "+cSolicit
		oProcess:bReturn  	:= "U_COMWF01a()"

		//**********************************************************************//
		// Fun��o a ser executada quando expirar o tempo do TimeOut.			//
		// Tempos limite de espera das respostas, em dias, horas e minutos.		//
		//**********************************************************************//
		//oProcess:bTimeOut := {{"U_COMWF01b()", Val(cDiasA) , 0, 0 },{"U_COMWF01c()", Val(cDiasE) , 0, 0 }}
		oProcess:bTimeOut := {{"U_COMWF01b()", 0 , 0, 3 },{"U_COMWF01c()", 0 , 0, 6 }}

		cMailID := oProcess:Start()

		PutMv("MV_WFHTML",cMvAtt)


		//*********************************************************
		//	Inicia o processo de enviar link no corpo do e-mail
		//*********************************************************

		oProcess:NewTask('000005', '\workflow\koala\COMWFLINK001.HTM')  //Inicio uma nova Task com um HTML Simples
		oProcess:oHtml:ValByName('proc_link',cHostWF+'/workflow/messenger/'+'/emp'+ cEmpAnt + '/koala/' + cMailId + '.HTM' )

		oHtml:ValByName("cNumSc"			, cNumSc)
		oHtml:ValByName("cSolicitante"		, cSolicit)
		oHtml:ValByName("dDtEmissao"		, dDtEmissao)

		oProcess:cTo    	:= cMailSup //E-mail do aprovador
		oProcess:cBCC     	:= "igor-d-silva@hotmail.com" //C�pia
		oProcess:cSubject  	:= "Aprova��o de SC - "+cNumSc+" - De: "+cSolicit

		oProcess:Start()
		oProcess:Free()
		oProcess:= Nil

		TRB->(dbCloseArea())

	Else

		TRB->(dbCloseArea())
		MsgStop("Problemas no Envio do E-Mail de Aprova��o!","ATEN��O!")

	EndIf

Return
// FIM da Funcao COMWF001
//======================================================================================================================


//======================================================================================================================
/*/{Protheus.doc} COMWF01a
  ======================================================================================================================
	@description
	Retorno do Workflow de Aprovacao de Solicitacao de Compras.
	
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return
	@param oProcess
	@type function
/*/
//======================================================================================================================
User Function COMWF01a(oProcess)

	Local cMvAtt := GetMv("MV_WFHTML")
	Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
	Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
	Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
	Local lAprov	:= oProcess:oHtml:RetByName("cAPROV") == 'L'
	Local cAprov	:= oProcess:oHtml:RetByName("cAPROV")
	Local cMotivo	:= oProcess:oHtml:RetByName("cMOTIVO")
	Local cCodSol	:= oProcess:oHtml:RetByName("cCODUSR")
	Local cMailSol 	:= UsrRetMail(cCodSol)
	Local cAliasZZA := ""
	Local cQuery 	:= ""
	Local cQueryZZA := ""
	Local aZZA 		:= {}
	Local nZZA 		:= 0
	Local lContinua := .T.
	Local lLiberou  := .F.

	Private oHtml

	ConOut("Aprovando SC: "+cNumSc)

	//Consulta grupo de aprovadores de sol. de compra ZZA
	cAliasZZA := GetNextAlias()
	cQueryZZA := " SELECT "
	cQueryZZA += " * FROM " + RetSqlName("ZZA")  + " ZZA "
	cQueryZZA += " WHERE D_E_L_E_T_ <> '*' "
	cQueryZZA += " AND ZZA_NUM = " + cNumSc
	cQueryZZA := ChangeQuery(cQueryZZA)

	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryZZA), cAliasZZA, .F., .T.)

	//Array aprovadores ZZA
	While (cAliasZZA)->(!Eof())
		AADD( aZZA,{ (cAliasZZA)->ZZA_NUM,		;	//1 - Num Doc
		(cAliasZZA)->ZZA_CODGRP,	;	//2 - C�d. grupo aprovador
		(cAliasZZA)->ZZA_USER,		;	//3 - C�d. usu�rio
		(cAliasZZA)->ZZA_NIVEL,		;  	//4 - N�vel
		(cAliasZZA)->ZZA_STATUS} )  	//5 - Status
		(cAliasZZA)->(DbSkip())
	EndDo

	/*For nZZA := 1 To Len(aZZA)
		cSuperior := aZZA[nZZA,3]

	If ! Empty(cSuperior) .And. aZZA[nZZA,4] == "01"
			//RecLock("SC1",.F.)
			//	C1_CODAPRO := cSuperior
			//MsUnlock()
			U_COMWF001(cAprov)	
	EndIf
		
Next nZZA*/


	// -----------------------------------------------
	// Avalia o Status do Documento a ser liberado
	// -----------------------------------------------
If lContinua .And. !Empty((cAliasZZA)->ZZA_DTLIB) .And. (cAliasZZA)->ZZA_STATUS $ '02'
		Conout('Este pedido ja foi liberado anteriormente. Somente os pedidos que estao aguardando liberacao poderao ser liberados.')
		lContinua := .F.

ElseIf lContinua .And. (cAliasZZA)->ZZA_STATUS $ '01'
		Conout('Esta opera��o n�o poder� ser realizada pois este registro se encontra bloqueado pelo sistema (aguardando outros niveis)')
		lContinua := .F.

EndIf

If !Empty((cAliasZZA)->ZZA_DTLIB) .And. (cAliasZZA)->ZZA_STATUS $ '02'

		//Faz libera��o se for aprovado
		cQuery := " UPDATE " + RetSqlName("SC1")
		cQuery += " SET C1_APROV = '"+cAprov+"'"
		cQuery += " WHERE C1_NUM = '"+cNumSc+"'"

		MemoWrit("COMWF01a.sql",cQuery)
		TcSqlExec(cQuery)
		TCREFRESH(RetSqlName("SC1"))
Else

		U_COMWF001(cAprov)	

EndIf

	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1002',"RETORNO DE WORKFLOW PARA APROVACAO DE SC",cUsername)

	oProcess:Finish()
	oProcess:Free()
	oProcess:= Nil

	//**************************************
	//	Inicia Envio de Mensagem de Aviso
	//**************************************
	PutMv("MV_WFHTML","T")

	oProcess:=TWFProcess():New("000004","WORKFLOW PARA APROVACAO DE SC")
If cAprov == "L" //Verifica se foi aprovado
		DbSelectArea("ZZA")
		DbSetOrder(2)
	If DbSeek(xFilial("ZZA")+cAprov)
			RecLock("ZZA", .F.)
				ZZA->ZZA_STATUS		:= "02"			//Status = 01 aguardando aprova��o | 02 aprovado | 03 rejeitado
				ZZA->ZZA_DTLIB 	:= Date()			//Data da libera��o
			MsUnLock() // Confirma e finaliza a opera��o
	EndIf
		oProcess:NewTask('Inicio',"\workflow\koala\COMWF005.htm")
ElseIf cAprov == "R" //Verifica se foi rejeitado
		DbSelectArea("ZZA")
		DbSetOrder(2)
	If DbSeek(xFilial("ZZA")+cAprov)
			RecLock("ZZA", .F.)
				ZZA->ZZA_STATUS		:= "03"			//Status = 01 aguardando aprova��o | 02 aprovado | 03 rejeitado
				ZZA->ZZA_DTLIB 	:= Date()			//Data da libera��o
			MsUnLock() // Confirma e finaliza a opera��o
	EndIf
		oProcess:NewTask('Inicio',"\workflow\koala\COMWF006.htm")
EndIf
	oHtml   := oProcess:oHtml

	oHtml:valbyname("Num"		, cNumSc)
	oHtml:valbyname("Req"    	, cSolicit)
	oHtml:valbyname("Emissao"   , cEmissao)
	oHtml:valbyname("Motivo"   , cMotivo)
	oHtml:valbyname("it.Item"   , {})
	oHtml:valbyname("it.Cod"  	, {})
	oHtml:valbyname("it.Desc"   , {})

	cQuery2 := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI"
	cQuery2 += " FROM "+RetSqlName("SC1")
	cQuery2 += " WHERE C1_NUM = '"+cNumSc+"'"

	MemoWrit("COMWF01a.sql",cQuery2)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB", .F., .T.)

	COUNT TO nRec
	//CASO TENHA DADOS
If nRec > 0
		
		dbSelectArea("TRB")
		dbGoTop()
		
	While !EOF()
			aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
			aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
			aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
			dbSkip()
	End
		
EndIf
	TRB->(dbCloseArea())

	//***********************************
	//	Funcoes para Envio do Workflow
	//***********************************
	
	//envia o e-mail
	cUser 			  := Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	
	CONOUT("e-MAIL: "+cMailSol)
	CONOUT("USERCOD "+cCodSol)
	
	oProcess:cTo	  := cMailSol
	oProcess:cBCC     := "igor-d-silva@hotmail.com"
	
If cAprov == "L" //Verifica se foi aprovado
		oProcess:cSubject := "SC N�: "+cNumSc+" - Aprovada"
ElseIf cAprov == "R" //Verifica se foi rejeitado
		oProcess:cSubject := "SC N�: "+cNumSc+" - Reprovada"
EndIf
	
	oProcess:cBody    := ""
	oProcess:bReturn  := ""
	oProcess:Start()

	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
If cAprov == "L" //Verifica se foi aprovado
		RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1005',"APROVACAO DE WORKFLOW DE SC",cUsername)
ElseIf cAprov == "R" //Verifica se foi rejeitado
		RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1006',"REJEICAO DE WORKFLOW DE SC",cUsername)
EndIf

	oProcess:Free()
	oProcess:Finish()
	oProcess:= Nil

	PutMv("MV_WFHTML",cMvAtt)

	WFSendMail({"01","01"})

Return
// FIM da Funcao COMWF01a
//======================================================================================================================


//======================================================================================================================
/*/{Protheus.doc} COMWF01b
  ======================================================================================================================
	@description 
	Envia um Aviso para Aprovador apos periodo de TIMEOUT.
	
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return 
	@param oProcess
	@type function
/*/
//======================================================================================================================
User Function COMWF01b(oProcess)

	Local cMvAtt 	:= GetMv("MV_WFHTML")
	Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
	Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
	Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
	Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
	Local cDiasE	:= oProcess:oHtml:RetByName("diasE")

	Private oHtml

	Conout("AVISO POR TIMEOUT SC:"+cNumSc+" Solicitante:"+cSolicit)

	oProcess:Free()
	oProcess:= Nil

	//*************************************
	//	Inicia Envio de Mensagem de Aviso
	//*************************************
	PutMv("MV_WFHTML","T")

	oProcess:=TWFProcess():New("000004","WORKFLOW PARA APROVACAO DE SC")
	oProcess:NewTask('Inicio',"\workflow\koala\COMWF003.htm")
	oHtml   := oProcess:oHtml

	oHtml:valbyname("Num"		, cNumSc)
	oHtml:valbyname("Req"    	, cSolicit)
	oHtml:valbyname("Emissao"   , cEmissao)
	oHtml:valbyname("diasA"   	, cDiasA)
	oHtml:valbyname("diasE"   	, Val(cDiasE)-Val(cDiasA))
	oHtml:valbyname("it.Item"   , {})
	oHtml:valbyname("it.Cod"  	, {})
	oHtml:valbyname("it.Desc"   , {})

	cQuery := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_CODAPRO"
	cQuery += " FROM " + RetSqlName("SC1")
	cQuery += " WHERE C1_NUM = '"+cNumSc+"'"

	MemoWrit("COMWF01b.sql",cQuery)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

	COUNT TO nRec
	//CASO TENHA DADOS
	If nRec > 0

		dbSelectArea("TRB")
		dbGoTop()
		cMailSup := UsrRetMail(TRB->C1_CODAPRO)
		While !EOF()
			aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
			aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
			aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
			dbSkip()
		End

	EndIf
	TRB->(dbCloseArea())

	//************************************
	//	Funcoes para Envio do Workflow
	//************************************

	//envia o e-mail
	cUser 			  := Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	oProcess:cTo	  := cMailSup
	oProcess:cBCC     := "igor-d-silva@hotmail.com"
	oProcess:cSubject := "Aviso de TimeOut de SC N�: "+cNumSc+" - De: "+cSolicit
	oProcess:cBody    := ""
	oProcess:bReturn  := ""
	oProcess:Start()
	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1003',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
	oProcess:Free()
	oProcess:Finish()
	oProcess:= Nil

	PutMv("MV_WFHTML",cMvAtt)

	WFSendMail({"01","01"})

Return
// FIM da Funcao COMWF01b
//======================================================================================================================


//======================================================================================================================
/*/{Protheus.doc} COMWF01c
  ======================================================================================================================
	@description 
	Exclui a solicitacao apos um periodo de TIMEOUT.
	
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return
	@param oProcess
	@type function
/*/
//======================================================================================================================
User Function COMWF01c(oProcess)

	Local cMvAtt
	Local cNumSc
	Local cSolicit
	Local cEmissao
	Local cDiasA
	Local cDiasE
	Local cCodSol
	Local cMailSol
	Local aCab := {}
	Local aItem:= {}
	Local aTables := {"SC1"}

	//Vari�veis para controlar o TXT
	Local aLogAuto := {}
	Local cLogTxt  := ""
	Local cArquivo := "C:\temp\LogMata110.txt"
	Local nAux     := 0

	//Vari�veis de controle do ExecAuto
	Private lMSHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.
	Private lMsErroAuto     := .F.

	Private oHtml

	If Select("SX6") == 0
		xEmp := "99"
		xFil := "01"
		RPCSetType(3)
		RpcSetEnv( xEmp,xFil, "admin", "", "COM", "MATA110", aTables, , , ,  )
	Endif

	cMvAtt 	:= SuperGetMV("MV_WFHTML",.F.,"")
	cNumSc	:= oProcess:oHtml:RetByName("cNUM")
	cSolicit:= oProcess:oHtml:RetByName("cSOLICIT")
	cEmissao:= oProcess:oHtml:RetByName("cEMISSAO")
	cDiasA	:= oProcess:oHtml:RetByName("diasA")
	cDiasE	:= oProcess:oHtml:RetByName("diasE")
	cCodSol	:= RetCodUsr(cSolicit)
	cMailSol:= UsrRetMail(cCodSol)

	Conout("EXCLUSAO POR TIMEOUT SC:"+cNumSc+" Solicitante:"+cSolicit)

	cQuery := " SELECT C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_CODAPRO"
	cQuery += " FROM " + RetSqlName("SC1")
	cQuery += " WHERE C1_NUM = '"+cNumSc+"'"

	MemoWrit("COMWF01c.sql",cQuery)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

	COUNT TO nRec
	//CASO TENHA DADOS
	If nRec > 0
		//*************************************
		//	Inicia MsExecAuto da Exclusao
		//*************************************

		ConOut("++++++++++   Inicio If nRec > 0 ++++++++")

		dbSelectArea("TRB")
		dbGoTop()

		cMailSup := UsrRetMail(TRB->C1_CODAPRO)

		While !EOF()
			lMsErroAuto := .F.
			aCab:= {		{"C1_NUM",cNumSc,NIL}}
			AADD(aItem, {	{"C1_ITEM",TRB->C1_ITEM,NIL}})

			Begin Transaction
				ConOut("++++++++++   Inicio MSExecAuto ++++++++")
				MSExecAuto({|x,y,z| mata110(x,y,z)},aCab,aItem,5) //Exclusao
				ConOut("++++++++++   Fim MSExecAuto ++++++++")
			End Transaction

			dbSkip()
		End

		//*************************************
		//	Tratamento de Log MsExecAuto
		//*************************************

		//Se houve erro
		If lMsErroAuto
			//Pegando log do ExecAuto
			aLogAuto := GetAutoGRLog()

			//Percorrendo o Log e incrementando o texto (para usar o CRLF voc� deve usar a include "Protheus.ch")
			For nAux := 1 To Len(aLogAuto)
				cLogTxt += aLogAuto[nAux] + CRLF
			Next

			//Criando o arquivo txt
			MemoWrite(cArquivo, cLogTxt)
		EndIf

		oProcess:Finish()
		oProcess:Free()
		oProcess:= Nil

		//*************************************
		//	Inicia Envio de Mensagem de Aviso
		//*************************************
		//PutMv("MV_WFHTML","T")

		oProcess:=TWFProcess():New("000004","WORKFLOW PARA APROVACAO DE SC")
		oProcess:NewTask('Inicio',"\workflow\koala\COMWF004.htm")
		oHtml   := oProcess:oHtml

		oHtml:valbyname("Num"		, cNumSc)
		oHtml:valbyname("Req"    	, cSolicit)
		oHtml:valbyname("Emissao"   , cEmissao)
		oHtml:valbyname("diasE"		, cDiasE)
		oHtml:valbyname("it.Item"   , {})
		oHtml:valbyname("it.Cod"  	, {})
		oHtml:valbyname("it.Desc"   , {})

		dbSelectArea("TRB")
		dbGoTop()

		While !EOF()
			aadd(oHtml:ValByName("it.Item")		, TRB->C1_ITEM)
			aadd(oHtml:ValByName("it.Cod")		, TRB->C1_PRODUTO)
			aadd(oHtml:ValByName("it.Desc")		, TRB->C1_DESCRI)
			dbSkip()
		End

	EndIf
	ConOut("++++++++++   Fim If nRec > 0 ++++++++")
	TRB->(dbCloseArea())

	//*************************************
	//	Funcoes para Envio do Workflow
	//*************************************

	//envia o e-mail
	cUser 			  := Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	oProcess:cTo	  := cMailSup+";"+cMailSol
	oProcess:cBCC     := "igor-d-silva@hotmail.com"
	oProcess:cSubject := "Exclus�o por TimeOut - SC N�: "+cNumSc+" - De: "+cSolicit
	oProcess:cBody    := ""
	oProcess:bReturn  := ""
	oProcess:Start()
	//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1004',"TIMEOUT EXCLUSAO DE WORKFLOW PARA APROVACAO DE SC",cUsername)
	oProcess:Free()
	oProcess:Finish()
	oProcess:= Nil

	PutMv("MV_WFHTML",cMvAtt)

	WFSendMail({"01","01"})

	RpcClearEnv() //Limpa o ambiente, liberando a licen�a e fechando as conex�es

Return
// FIM da Funcao COMWF01c
//======================================================================================================================
