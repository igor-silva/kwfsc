#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF001
//TODO Descri��o: Envia Workflow de Aprovacao de Solicitacao de Compras.
		Para quando a aprovacao e feita por SOLICITACAO
		@author Igor Silva
		@since 06/03/2020
		@version 1.0
		@return ${return}, ${return_description}
		@param cAprov, characters, descricao
		@type function
/*/
User Function COMWF001(cAprov)

//***************************
//	Declara��o de Variaveis
//***************************
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
	End
	
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
	
	oProcess:newtask('000005', '\workflow\koala\COMWFLINK001.HTM')  //Inicio uma nova Task com um HTML Simples
  	oProcess:ohtml:valbyname('proc_link',cHostWF+'/workflow/messenger/'+'/emp'+ cEmpAnt + '/koala/' + cMailId + '.HTM' ) //Defino o Link onde foi gravado o HTML pelo Workflow,abaixo do diret�rio do usu�rio definido em cTo do processo acima.


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