#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT110GRV
//Ponto de entrada apos gravação da SC. 
@author Igor Silva
@since 11/03/2020
@version 1.0
@return ${return}, ${return_description}
@type function	
/*/
User Function MT110GRV()

	Local aArea	:= GetArea()
	Local lRet 	:= .T.

	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	//	Envia Workflow para aprovacao da Solicitacao de Compras
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	If INCLUI .OR. ALTERA //Verifica se e Inclusao ou Alteracao da Solicitacao
		MsgRun("Enviando Workflow para Aprovador da Solicitação, Aguarde...","",{|| CursorWait(), U_COMRD003() ,CursorArrow()})	
	EndIf

	DbSelectArea("SC1")
		//Grava campo C1_SPORTAL
		If SC1->C1_SPORTAL == .F. .And. SC1->C1_WFENVIO == .F. 
			RecLock("SC1", .F.)		
			SC1->C1_SPORTAL := .F. 
			SC1->C1_WFENVIO := .T.
			MsUnLock() // Confirma e finaliza a operação
		EndIf
	SC1->(DbCloseArea())
	
	RestArea(aArea)

Return lRet