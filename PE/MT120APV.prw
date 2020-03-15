#Include "Rwmake.ch"
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"

/*
+------------+----------+-------+------------------------------------------------------+------+----------------+
|Programa    | MT120APV | Autor | Fabrica Tecnorav                                     | Data | Fevereiro/2020 |
+------------+----------+-------+------------------------------------------------------+------+----------------+
|Descricao   | Ponto de entrada para alterar o grupo de aprovadores do pedido de compras                       |
+------------+-------------------------------------------------------------------------------------------------+
|Uso         | Contrail	                                													   |
+------------+-------------------------------------------------------------------------------------------------+
*/

User Function MT120APV()

Local cAprov	:= ""
Private cAp		:= ""

U_FPARVTIP(cAp)

cAprov := cAp

If !Empty(cAprov)
	
	If FunName() == "MATA121"
		cNumPed	:= SC7->C7_NUM 
		
		dbSelectArea("SC7")
		dbSetOrder(1)
		
		If DbSeek(xFilial("SC7") + cNumPed + "0001")
			
			While !Eof() .And. SC7->C7_NUM  == cNumPed
				
				While !RecLock("SC7",.f.)
				Enddo
				SC7->C7_APROV := cAprov
				MsUnlock()
				
				DbSelectArea("SC7")
				DbSkip()
			EndDo
			
		EndIf
	EndIf
EndIf

Return(cAprov)

/*
+------------+-------------------------------------------------------------------------------------------------+
*/

User Function FPARVTIP(cPar)

Local cQuery	:= ""
Local aDados 	:= {}
Local aUserId	:= {}
Local lOk		:= .T.       

If Select("QSAL") > 0
	DbSelectArea("QSAL")
	DbCloseArea()
EndIf

cQuery := " SELECT AL_COD, AL_DESC, AL_USER"
cQuery += "  FROM "+RetSqlName("SAL")"
cQuery += " WHERE "+RetSqlName("SAL")+".D_E_L_E_T_ = ''"
cQuery += "   AND AL_FILIAL = '"+xFilial("SAL")+"'"
cQuery += "   AND LEFT(AL_COD,1) <> '0' "
cQuery += " ORDER BY AL_COD, AL_USER"

TcQuery cQuery New Alias "QSAL"

DbSelectArea("QSAL")
DbGoTop()
While QSAL->(!Eof())
	If Alltrim(QSAL->AL_USER) == Alltrim(__cUserID)
		AADD(aUserId,QSAL->AL_COD)
	EndIf
	QSAL->(DbSkip())
EndDo

If Select("QSAL") > 0
	DbSelectArea("QSAL")
	DbCloseArea()
EndIf

cQuery	:= ""

cQuery := "SELECT DISTINCT AL_COD, AL_DESC"
cQuery += "  FROM "+RetSqlName("SAL")"
cQuery += " WHERE "+RetSqlName("SAL")+".D_E_L_E_T_ = ''"
cQuery += "   AND AL_FILIAL = '"+xFilial("SAL")+"'"
cQuery += "   AND LEFT(AL_COD,1) <> '0' "
cQuery += " ORDER BY AL_DESC"

TcQuery cQuery New Alias "QSAL"

cQuery	:= ""

DbSelectArea("QSAL")
DbGoTop()

MvParDef 	:= ""
cPar2		:= AllTrim(cPar)
cPar 		:= AllTrim(&cPar)

While QSAL->(!Eof())
	AADD(aDados,StrTran(QSAL->AL_DESC,"-"," "))
	MvParDef += Left(QSAL->AL_COD,6)
	QSAL->(DbSkip())
EndDo

If Select("QSAL") > 0
	DbSelectArea("QSAL")
	DbCloseArea()
EndIf

While lOk
	If f_Opcoes(@cPar,"Por favor, selecione o aprovador para o Pedido de Compra.",aDados,MvParDef,,,.t.,6,30)
		cAp	:= AllTrim(StrTran(cPar,"*",""))
		If !Empty(Alltrim(cAp))
			lOk	:= .F.
		Else
			Alert("É necessário selecionar o aprovador.","Alerta")
		EndIf
	Else
		Alert("É necessário selecionar o aprovador.","Alerta")
	EndIf
EndDo

Return(.t.)