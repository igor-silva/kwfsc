#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF02c
//TODO Descrição: Exclui a solicitacao apos um periodo de TIMEOUT.
@author Igor Silva
@since 06/03/2020
@version 1.0
@return ${return}, ${return_description}
@param oProcess, object, descricao
@type function
/*/
User Function COMWF02c(oProcess)
Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("Num")
Local cItemSc	:= oProcess:oHtml:RetByName("Item")
Local cSolicit	:= oProcess:oHtml:RetByName("Req")
Local cEmissao	:= oProcess:oHtml:RetByName("Emissao")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCod		:= oProcess:oHtml:RetByName("CodProd")
Local cDesc		:= oProcess:oHtml:RetByName("Desc")
Local cCodSol	:= RetCodUsr(cSolicit)
Local cMailSol 	:= UsrRetMail(cCodSol)
Private oHtml

ConOut("EXCLUSAO POR TIMEOUT SC:"+cNumSc+" Item:"+cItemSc+" Solicitante:"+cSolicit)

cQuery := " UPDATE " + RetSqlName("SC1")
cQuery += " SET D_E_L_E_T_ = '*'"
cQuery += " WHERE C1_NUM = '"+cNumSc+"'"
cQuery += " AND C1_ITEM = '"+cItemSc+"'"

MemoWrit("COMWF02c.sql",cQuery)
TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))

oProcess:Finish()
oProcess:Free()
oProcess:= Nil

//*************************************
//	Inicia Envio de Mensagem de Aviso
//*************************************
PutMv("MV_WFHTML","T")

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
aadd(oHtml:ValByName("it.Item")		, cItemSc)
aadd(oHtml:ValByName("it.Cod")		, cCod)
aadd(oHtml:ValByName("it.Desc")		, cDesc)

//**********************************
//	Funcoes para Envio do Workflow
//**********************************

//envia o e-mail
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup+";"+cMailSol
oProcess:cBCC     := "igor-d-silva@hotmail.com"
oProcess:cSubject := "Exclusão por TimeOut - SC N°: "+cNumSc+" Item: "+cItemSc+" - De: "+cSolicit
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

Return