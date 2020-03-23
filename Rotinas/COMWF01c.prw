#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF01c
//TODO Descrição: Exclui a solicitacao apos um periodo de TIMEOUT .
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return ${return}, ${return_description}
	@param oProcess, object, descricao
	@type function
/*/
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

//Variáveis para controlar o TXT
Local aLogAuto := {}
Local cLogTxt  := ""
Local cArquivo := "C:\temp\LogMata110.txt"
Local nAux     := 0
 
//Variáveis de controle do ExecAuto
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

ConOut("EXCLUSAO POR TIMEOUT SC:"+cNumSc+" Solicitante:"+cSolicit)

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
		Aadd(aItem, {	{"C1_ITEM",TRB->C1_ITEM,NIL}})
		
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
	
		//Percorrendo o Log e incrementando o texto (para usar o CRLF você deve usar a include "Protheus.ch")
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
ConOut("++++++++++   Inicio If nRec > 0 ++++++++")
TRB->(dbCloseArea())

//*************************************
//	Funcoes para Envio do Workflow
//*************************************

//envia o e-mail
cUser 			  := Subs(cUsuario,7,15)
oProcess:ClientName(cUser)
oProcess:cTo	  := cMailSup+";"+cMailSol
oProcess:cBCC     := "igor-d-silva@hotmail.com"
oProcess:cSubject := "Exclusão por TimeOut - SC N°: "+cNumSc+" - De: "+cSolicit
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

RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões

Return