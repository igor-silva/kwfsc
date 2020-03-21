#include 'protheus.ch'
#include 'parmtype.ch'


 /*/{Protheus.doc} CopiaFile
    (long_description)
    @type  Function
    @author user
    @since 21/03/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function CopiaFile()


//Definindo os diretórios
Local cDirUsr  := "C:\temp\test"
Local cDirSrv  := '\workflow\'
//Local cDirFull := '\\localhost\Protheus_Data' + cDirSrv
Local aDirAux  := Directory(cDirSrv+'*.htm')
Local nAtual   := 0

Alert("Iniciou")

//Percorre os arquivos
For nAtual := 1 To Len(aDirAux)
    //Pegando o nome do arquivo
    cNomArq := aDirAux[nAtual][1]

    Alert("Nome do arquivo no laço For: " + cNomArq)
     
    //Copia o arquivo do Servidor para a máquina do usuário
    If CpyS2T( cDirSrv+cNomArq, cDirUsr, .F. ) 

    Alert("Copiado com sucesso!")

    Else
        Alert("Erro ao copiar.")
    EndIf
Next nAtual


Alert("Finalizou")

Return 