#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF01a
//TODO Descrição: Retorno do Workflow de Aprovacao de Solicitacao de Compras.
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return ${return}, ${return_description}
	@param oProcess, object, descricao
	@type function
/*/
User Function COMWF01a(oProcess)

Local cMvAtt := GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("cNUM")
Local cSolicit	:= oProcess:oHtml:RetByName("cSOLICIT")
Local cEmissao	:= oProcess:oHtml:RetByName("cEMISSAO")
Local cAprov	:= oProcess:oHtml:RetByName("cAPROV")
Local cMotivo	:= oProcess:oHtml:RetByName("cMOTIVO")
Local cCodSol	:= oProcess:oHtml:RetByName("cCODUSR")
Local cMailSol 	:= UsrRetMail(cCodSol)

Private oHtml

ConOut("Aprovando SC: "+cNumSc)

cQuery := " UPDATE " + RetSqlName("SC1")
cQuery += " SET C1_APROV = '"+cAprov+"'"
cQuery += " WHERE C1_NUM = '"+cNumSc+"'"

MemoWrit("COMWF01a.sql",cQuery)
TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))


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
	oProcess:NewTask('Inicio',"\workflow\koala\COMWF005.htm")
ElseIf cAprov == "R" //Verifica se foi rejeitado
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
//oProcess:cTo	  := "igor-d-silva@hotmail.com"
CONOUT("e-MAIL: "+cMailSol)
CONOUT("USERCOD "+cCodSol)
oProcess:cTo	  := cMailSol
oProcess:cBCC     := "igor-d-silva@hotmail.com"
If cAprov == "L" //Verifica se foi aprovado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Aprovada"
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Reprovada"
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
