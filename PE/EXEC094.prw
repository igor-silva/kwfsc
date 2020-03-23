#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
 
User Function Exec094(cNumDoc,cTipoDoc)
 
    Local oModel094 := Nil      //-- Objeto que receberá o modelo da MATA094
    Local cNum      := cNumDoc     //-- Recebe o número do documento a ser avaliado
    Local cTipo     := cTipoDoc    //-- Recebe o tipo do documento a ser avaliado
    Local cAprov    := ""   //-- Recebe o código do aprovador do documento
    Local nLenSCR   := 0        //-- Controle de tamanho de campo do documento
    Local lOk       := .T.      //-- Controle de validação e commit
    Local aErro     := {}       //-- Recebe msg de erro de processamento
 
    //-- Inicializa o ambiente
    PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" USER "Administrador" PASSWORD "" MODULO "COM"
     
    nLenSCR := TamSX3("CR_NUM")[1] //-- Obtem tamanho do campo CR_NUM
    DbSelectArea("SCR")
    SCR->(DbSetOrder(3)) //-- CR_FILIAL+CR_TIPO+CR_NUM+CR_APROV
 
    If SCR->(DbSeek(xFilial("SCR") + cTipo + Padr(cNum, nLenSCR) + cAprov))
 
        //-- Códigos de operações possíveis:
        //--    "001" // Liberado
        //--    "002" // Estornar
        //--    "003" // Superior
        //--    "004" // Transferir Superior
        //--    "005" // Rejeitado
        //--    "006" // Bloqueio
        //--    "007" // Visualizacao
 
        //-- Seleciona a operação de aprovação de documentos
        A094SetOp('001')
 
        //-- Carrega o modelo de dados e seleciona a operação de aprovação (UPDATE)
        oModel094 := FWLoadModel('MATA094')
        oModel094:SetOperation( MODEL_OPERATION_UPDATE )
        oModel094:Activate()
 
        //-- Valida o formulário
        lOk := oModel094:VldData()
 
        If lOk
            //-- Se validou, grava o formulário
            lOk := oModel094:CommitData()
        EndIf
 
        //-- Avalia erros
        If !lOk
            //-- Busca o Erro do Modelo de Dados
            aErro := oModel094:GetErrorMessage()
                  
            //-- Monta o Texto que será mostrado na tela
            AutoGrLog("Id do formulário de origem:" + ' [' + AllToChar(aErro[01]) + ']')
            AutoGrLog("Id do campo de origem: "     + ' [' + AllToChar(aErro[02]) + ']')
            AutoGrLog("Id do formulário de erro: "  + ' [' + AllToChar(aErro[03]) + ']')
            AutoGrLog("Id do campo de erro: "       + ' [' + AllToChar(aErro[04]) + ']')
            AutoGrLog("Id do erro: "                + ' [' + AllToChar(aErro[05]) + ']')
            AutoGrLog("Mensagem do erro: "          + ' [' + AllToChar(aErro[06]) + ']')
            AutoGrLog("Mensagem da solução:"        + ' [' + AllToChar(aErro[07]) + ']')
            AutoGrLog("Valor atribuído: "           + ' [' + AllToChar(aErro[08]) + ']')
            AutoGrLog("Valor anterior: "            + ' [' + AllToChar(aErro[09]) + ']')
 
            //-- Mostra a mensagem de Erro
            MostraErro()
        EndIf
 
        //-- Desativa o modelo de dados
        oModel094:DeActivate()
 
    Else
        MsgInfo("Documento não encontrado!", "Exec094")
    EndIf
     
    //-- Finaliza o ambiente
    RESET ENVIRONMENT
 
Return Nil