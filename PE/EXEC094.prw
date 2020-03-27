#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
 
User Function Exec094(cNumDoc,cTipoDoc,cUser,cAprovDoc,cGrupo,cNivelAp,cStatus,dEmissao,cTotal)
 
    Local oModel094 := Nil      	//-- Objeto que receber� o modelo da MATA094
    Local cNum      := cNumDoc 		//-- Recebe o n�mero do documento a ser avaliado
    Local cTipo     := cTipoDoc 	//-- Recebe o tipo do documento a ser avaliado
    Local cAprov    := cAprovDoc 	//-- Recebe o c�digo do aprovador do documento
    Local nLenSCR   := 0        	//-- Controle de tamanho de campo do documento
    Local lOk       := .T.      	//-- Controle de valida��o e commit
    Local aErro     := {}       	//-- Recebe msg de erro de processamento
     
    nLenSCR := TamSX3("CR_NUM")[1] //-- Obtem tamanho do campo CR_NUM
 
    If !Empty(cNum)
 
        //-- Carrega o modelo de dados e seleciona a opera��o de aprova��o (UPDATE)
        oModel094 := FWLoadModel('MATA094')
        oModel094:SetOperation( MODEL_OPERATION_INSERT )
		oModel094:Activate()
		
				
		//Pegando o model dos campos da SCR
		oModel094:= oModel:getModel("MATA094_SCR")
		oModel094:setValue("CR_FILIAL",	xFilial("SCR")	) // Codigo 
		oModel094:setValue("CR_NUM",	cNumDoc       	) // Num. Documento            
		oModel094:setValue("CR_TIPO",	cTipoDoc		) // Tipo Documento 
		oModel094:setValue("CR_USER",	cUser   		) // Usu�rio
		oModel094:setValue("CR_APROV",	cAprov     		) // Aprovador
		oModel094:setValue("CR_GRUPO",	cGrupo         	) // Grupo de aprova��o 
		oModel094:setValue("CR_NIVEL",	cNivelAp     	) // N�vel do aprovador               
		oModel094:setValue("CR_STATUS",	cStatus    		) // Status da aprova��o
		oModel094:setValue("CR_EMISSAO",dEmissao        ) // Data de emiss�o do docuemnto
		oModel094:setValue("CR_TOTAL",	cTotal         	) // Total do documento
 
        //-- Valida o formul�rio
        lOk := oModel094:VldData()
 
        If lOk
            //-- Se validou, grava o formul�rio
            lOk := oModel094:CommitData()
        EndIf
 
        //-- Avalia erros
        If !lOk
            //-- Busca o Erro do Modelo de Dados
            aErro := oModel094:GetErrorMessage()
                  
            //-- Monta o Texto que ser� mostrado na tela
            AutoGrLog("Id do formul�rio de origem:" + ' [' + AllToChar(aErro[01]) + ']')
            AutoGrLog("Id do campo de origem: "     + ' [' + AllToChar(aErro[02]) + ']')
            AutoGrLog("Id do formul�rio de erro: "  + ' [' + AllToChar(aErro[03]) + ']')
            AutoGrLog("Id do campo de erro: "       + ' [' + AllToChar(aErro[04]) + ']')
            AutoGrLog("Id do erro: "                + ' [' + AllToChar(aErro[05]) + ']')
            AutoGrLog("Mensagem do erro: "          + ' [' + AllToChar(aErro[06]) + ']')
            AutoGrLog("Mensagem da solu��o:"        + ' [' + AllToChar(aErro[07]) + ']')
            AutoGrLog("Valor atribu�do: "           + ' [' + AllToChar(aErro[08]) + ']')
            AutoGrLog("Valor anterior: "            + ' [' + AllToChar(aErro[09]) + ']')
 
            //-- Mostra a mensagem de Erro
            MostraErro()
        EndIf
 
        //-- Desativa o modelo de dados
        oModel094:DeActivate()
 
    Else
        MsgInfo("Documento n�o encontrado!", "Exec094")
    EndIf

/*DbSelectArea("SCR")
//Grava campo SRC
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
	MsUnLock() // Confirma e finaliza a opera��o
SCR->(DbCloseArea())
EndIf*/
 
Return Nil