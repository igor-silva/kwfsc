#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
 
User Function Exec094(cNumDoc,cTipoDoc,cUser,cAprov,cGrupo,cNivelAp,cStatus,dEmissao,cTotal)
 
DbSelectArea("SCR")
//Grava campo C1_SPORTAL
If !Empty(cNumDoc) 
	RecLock("SCR", .T.)
        SCR->CR_FILIAL  := xFilial("SCR") 
		SCR->CR_NUM     := cNumDoc 
		SCR->CR_TIPO    := cTipoDoc
        SCR->CR_USER    := cUser
        SCR->CR_APROV   := cAprov
        SCR->CR_GRUPO   := cGrupo
        SCR->CR_NIVEL   := cNivelAp
        SCR->CR_STATUS  := cStatus
        SCR->CR_EMISSAO := dEmissao
        SCR->CR_TOTAL   := cTotal
	MsUnLock() // Confirma e finaliza a operação
SCR->(DbCloseArea())
EndIf
 
Return Nil