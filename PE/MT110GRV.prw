/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³  MT110GRV³ Autor ³ Thiago Comelli        ³ Data ³ 21/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Ponto de entrada apos gravação da SC.                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ MP8                                                        ³±±
±±³          ³ Necessario Criar Campo                                     ³±±
±±³          ³ Nome			Tipo	Tamanho	Titulo			OBS           ³±±
±±³          ³ C1_CODAPROV   C         6    Cod Aprovador                 ³±±
±±³          ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/



/*/{Protheus.doc} MT110GRV
//TODO Descrição auto-gerada.
@author Igor Silva
@since 11/03/2020
@version 1.0
@return ${return}, ${return_description}

@type function

	@obs Necessario criar Campo C1_CODAPRO para ser gravado o código do aprovador
	@param Nome: C1_CODAPRO		
	@param Tipo: C	
	@param Tamanho: 6		
	@param Titulo: Cod Aprovador
	
	@obs Necessario criar Campo C1_SPORTAL para ser gravado se a Sc de compra foi pelo portal ou não,
	.T. para sim e .F. para não.
	@param Nome: C1_SPORTAL	
	@param Tipo: L	
	@param Tamanho: 1		
	@param Titulo: Sc Portal
	
	@obs Necessario criar Campo C1_WFENVIO para ser gravado se o WF foi enviado  ou não,
	.T. para sim e .F. para não.
	@param Nome: C1_WFENVIO	
	@param Tipo: L	
	@param Tamanho: 1		
	@param Titulo: WF Envio
	
/*/

User Function MT110GRV()

Local aArea     := GetArea()
Local cRet := .T.

//GRAVA O NOME DA FUNCAO NA Z03
//U_CFGRD001(FunName())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Envia Workflow para aprovacao da Solicitacao de Compras ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If INCLUI .OR. ALTERA //Verifica se e Inclusao ou Alteracao da Solicitacao
	MsgRun("Enviando Workflow para Aprovador da Solicitação, Aguarde...","",{|| CursorWait(), U_COMRD003() ,CursorArrow()})
EndIf


DbSelectArea("SC1")
//Grava campo C1_SPORTAL
If SC1->C1_SPORTAL == .F. .And. SC1->C1_WFENVIO == .F. 
	RecLock("SC1", .F.)		
		SC1->C1_SPORTAL := .T. 
		SC1->C1_WFENVIO := .T.
	MsUnLock() // Confirma e finaliza a operação
SC1->(DbCloseArea())
EndIf



RestArea(aArea)

Return cRet