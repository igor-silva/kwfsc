 /*/{Protheus.doc} nomeFunction
    Valida se o usu�rio pode excluir a SC.
    @type  Function
    @author Igor Silva
    @since 22/03/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6085449
    /*/
User Function MT110VLD()

Local lRet := .T.
Local cUserSC := SC1->C1_USER

If ( cUserSC <> RetCodUsr() )

    Alert("Somente o usu�rio que cadastrou a solicita��o de compra pode realizar a exclus�o.")
    Return .F.

EndIf
    
Return lRet