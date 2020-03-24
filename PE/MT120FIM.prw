 /*/{Protheus.doc} MT120FIM

    Ponto de entrada localizado no final do processo de gravacao
    do pedido de compra. Sera utilizado para montagem e envio do
    processo de workflow  

    @type  Function
    @author user
    @since 23/03/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function MT120FIM()

    Local nOpc      := PARAMIXB[1]
	Local cNumPC    := PARAMIXB[2]
	Local lOk       := PARAMIXB[3] == 1
	
	
	If nOpc == 3 .And. lOk 
		MsgRun('Montando processo de Workflow...', 'Aguarde...', {|| U_WFPCSend(cNumPC)})
	EndIf
	
Return 