#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF02a
//TODO Descrição: Retorno Workflow de Aprovacao de Solicitacao de Compras .
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return ${return}, ${return_description}
	@param oProcess, object, descricao
	@type function
/*/
User Function COMWF02a(oProcess)

Local cMvAtt := GetMv("MV_WFHTML")
Local cNumSc	:= oProcess:oHtml:RetByName("Num")
Local cItemSc	:= oProcess:oHtml:RetByName("Item")
Local cSolicit	:= oProcess:oHtml:RetByName("Req")
Local cEmissao	:= oProcess:oHtml:RetByName("Emissao")
Local cDiasA	:= oProcess:oHtml:RetByName("diasA")
Local cDiasE	:= oProcess:oHtml:RetByName("diasE")
Local cCod		:= oProcess:oHtml:RetByName("CodProd")
Local cDesc		:= oProcess:oHtml:RetByName("Desc")
Local cAprov	:= oProcess:oHtml:RetByName("cAPROV")
Local cMotivo	:= oProcess:oHtml:RetByName("cMOTIVO")

Private oHtml

ConOut("Atualizando SC:"+cNumSc+" Item:"+cItemSc)

cQuery := " UPDATE " + RetSqlName("SC1")
cQuery += " SET C1_APROV = '"+cAprov+"'"
cQuery += " WHERE C1_NUM = '"+cNumSc+"'"
cQuery += " AND C1_ITEM = '"+cItemSc+"'"

MemoWrit("COMWF02a.sql",cQuery)
TcSqlExec(cQuery)
TCREFRESH(RetSqlName("SC1"))

//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1002',"RETOR DE WORKFLOW PARA APROVACAO DE SC",cUsername)

oProcess:Finish()
oProcess:Free()
oProcess:= Nil

//*************************************
//	Inicia Envio de Mensagem de Aviso
//*************************************
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
aadd(oHtml:ValByName("it.Item")		, cItemSc)
aadd(oHtml:ValByName("it.Cod")		, cCod)
aadd(oHtml:ValByName("it.Desc")		, cDesc)

//**********************************
//	Funcoes para Envio do Workflow
//**********************************
//envia o e-mail
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup
oProcess:cBCC     := "igor-d-silva@hotmail.com"

If cAprov == "L" //Verifica se foi aprovado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Item: "+cItemSc+" - Aprovada"
ElseIf cAprov == "R" //Verifica se foi rejeitado
	oProcess:cSubject := "SC N°: "+cNumSc+" - Item: "+cItemSc+" - Reprovada"
EndIf

oProcess:cBody    := ""
oProcess:bReturn  := ""
oProcess:Start()

//RastreiaWF( ID do Processo, Codigo do Processo, Codigo do Status, Descricao Especifica, Usuario )
If cAprov == "L" //Verifica se foi aprovado
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1005',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
ElseIf cAprov == "R" //Verifica se foi rejeitado
	RastreiaWF(oProcess:fProcessID+'.'+oProcess:fTaskID,"000004",'1006',"TIMEOUT DE WORKFLOW PARA APROVACAO DE SC",cUsername)
EndIf

oProcess:Free()
oProcess:Finish()
oProcess:= Nil

PutMv("MV_WFHTML",cMvAtt)

WFSendMail({"01","01"})

Return