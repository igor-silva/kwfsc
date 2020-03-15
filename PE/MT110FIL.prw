/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMT110FIL  บAutor  ณIGOR SILVA      บ Data ณ  03/03/20   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณPONTO DE ENTRADA NO FILTRO DO MBROWE DE SOLICITACAO DE COMPRบฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                              	                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MT110FIL()

//GRAVA O NOME DA FUNCAO NA Z03
//U_CFGRD001(FunName())

cRet := ""
CPERG := "COMRD3"
                 
//ValidPerg()
SetKey( 121 ,{|| Pergunte("COMRD3",.T.)})

Return (cRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณValidPerg บAutor  ณPaulo Bindo         บ Data ณ  12/01/05   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCria pergunta no e o help do SX1                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

//https://tdn.totvs.com/pages/viewpage.action?pageId=22479548

Static Function ValidPerg()


Local i,j := 0
Local aAreaAnt := GetArea()
aRegs  :={}

dbSelectArea("SX1")
dbSetOrder(1)

/*
 Campos  		Tipo       			Descri็ใo

X1_GRUPO		Caracter			C๓digo chave de identifica็ใo da pergunta. Atrav้s deste c๓digo as perguntas sใo agrupadas em um conjunto
X1_ORDEM		Caracter			Ordem de apresenta็ใo das perguntas. A ordem ้ importante para a cria็ใo das variแveis de escopo PRIVATE MV_PAR??
X1_PERGUNT		Caracter			R๓tulo com a descri็ใo da pergunta no idioma Portugu๊s
X1_PERSPA		Caracter			R๓tulo com a descri็ใo da pergunta no idioma Espanhol
X1_PERENG		Caracter			R๓tulo com a descri็ใo da pergunta no idioma Ingl๊s
X1_VARIAVL		Caracter			*** Nใo usado *** 
X1_TIPO			Caracter			Tipo de dado da pergunta, onde temos: C – Caracter,L- L๓gico,D-Data,N-Num้rico,	M-Memo           
X1_TAMANHO		Inteiro 			Tamanho do Campo
X1_DECIMAL		Inteiro				Quantidade de casas decimais, se o tipo for num้rico
X1_PRESEL		Inteiro				Quando temos uma Pergunta tipo Combo, podemos deixar o valor padrใo selecionado neste campo, deve ser informado qual o n๚mero da op็ใo selecionada.
X1_GSC			Caracter			Tipo de objeto a ser criado para essa pergunta, valores aceitos sใo:(G) Edit,(S)Text,(C) Combo,(R) Range,File,Expression ou (K)=Check.
									Caso campo esteja em branco ้ tratado como Edit. Objetos do tipo combo podem ter no mแximo 5 itens.
X1_VALID		Caracter			Valida็ใo da Pergunta. A fun็ใo deverแ ser Function(para GDPs) ou User Function (Cliente) , Static Function nใo podem ser utilizadas.
X1_VAR01		Caracter			Nome da variแvel criada para essa pergunta, no modelo MV_PARXXX, onde XXX ้ um sequencial num้rico.
X1_DEF01		Caracter			Item 1 do combo Box quando o X1_GSC igual a C. Em Portugu๊s.
X1_DEFSPA1		Caracter			Item 1 do combo Box quando o X1_GSC igual a C. Em Espanhol.
X1_DEFENG1		Caracter			Item 1 do combo Box quando o X1_GSC igual a C. Em Ingl๊s.
X1_CNT01		Caracter			Conte๚do inicial da variavel1, usada quando X1_GSC for Text ou Range,
X1_VAR02		Caracter		 	*** Nใo usado ***
X1_DEF02		Caracter			Item 2 do combo Box quando o X1_GSC igual a C. Em Portugu๊s.
X1_DEFSPA2		Caracter			Item 2 do combo Box quando o X1_GSC igual a C. Em Espanhol.
X1_DEFENG2		Caracter			Item 2 do combo Box quando o X1_GSC igual a C. Em Ingl๊s.
X1_CNT02		Caracter			*** Nใo usado ***
X1_VAR03		Caracter			*** Nใo usado ***
X1_DEF03		Caracter			Item 3 do combo Box quando o X1_GSC igual a C. Em Portugu๊s.
X1_DEFSPA3		Caracter			Item 3 do combo Box quando o X1_GSC igual a C. Em Espanhol.
X1_DEFENG3		Caracter			Item 3 do combo Box quando o X1_GSC igual a C. Em Ingl๊s.
X1_CNT03		Caracter			*** Nใo usado ***
X1_VAR04		Caracter			*** Nใo usado ***
X1_DEF04		Caracter			Item 4 do combo Box quando o X1_GSC igual a C. Em Portugu๊s.
X1_DEFSPA4		Caracter			Item 4 do combo Box quando o X1_GSC igual a C. Em Espanhol.
X1_DEFENG4		Caracter			Item 4 do combo Box quando o X1_GSC igual a C. Em Ingl๊s.
X1_CNT04		Caracter			*** Nใo usado ***
X1_VAR05		Caracter			*** Nใo usado ***
X1_DEF05		Caracter			Item 5 do combo Box quando o X1_GSC igual a C. Em Portugu๊s.
X1_DEFSPA5		Caracter			Item 5 do combo Box quando o X1_GSC igual a C. Em Espanhol.
X1_DEFENG5		Caracter			Item 5 do combo Box quando o X1_GSC igual a C. Em Ingl๊s.
X1_CNT05		Caracter			*** Nใo usado ***
X1_F3			Caracter			LookUp associado a pergunta
X1_PYME			Caracter			Determina se a pergunta ้ utilizada pelo Microsiga Protheus Serie 3
X1_GRPSXG		Caracter			C๓digo do grupo de campo(SXG) que o campo pertence. Todos os campos que estใo associados a um grupo de campo, sofrem as altera็๕es quando alteramos ele.
X1_HELP			Caracter			C๓digo do HELP para a pergunta.
X1_PICTURE		Caracter			Picture do Campo. A picture de um campo ้ a mascara de entrada que o campo deve respeitar. 
X1_IDFIL		Caracter			Utilizado quando o Registro do SX1 estแ sendo utilizado por filtro. Grupo ficarแ em branco nesse caso.
*/

////X1_GRUPO,X1_ORDEM,X1_PERGUNT,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAMANHO,X1_DECIMAL,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEFSPA1,X1_DEFENG1,X1_CNT01,X1_VAR02,X1_DEF02,X1_DEFSPA2,X1_DEFENG2,X1_CNT02,X1_VAR03,X1_DEF03,X1_DEFSPA3,X1_DEFENG3,X1_CNT03,X1_VAR04,X1_DEF04,X1_DEFSPA4,X1_DEFENG4,X1_CNT04,X1_VAR05,X1_DEF05,X1_DEFSPA5,X1_DEFENG5,X1_CNT05,X1_F3,X1_PYME,X1_GRPSXG,X1_HELP,X1_PICTURE,X1_IDFIL	
AADD(CPERG,{"01"	,"Nฐ de Pedidos?",""  ,""     	,"mv_ch1"	,"N"   ,02        ,0       	 ,0        ,"G"	  ,""      ,"mv_par01",""    ,""   		,"",""     ,""      ,""      ,""      ,""	   	,""     	,""      ,""      ,""      ,""        ,""    	 ,""      ,""      ,""    	,""        ,""        ,""      ,""      ,""      ,""		,""		   ,""		,""	  ,""	  ,""		,""		,""		   ,""})
AADD(CPERG,{"02","Nฐ de Fornecedores?","" ,""     	,"mv_ch2"	,"N"   ,02        ,0       	 ,0        ,"G"   ,""      ,"mv_par02",""    ,""   		,"",""     ,""      ,""      ,""      ,""		,""     	,""      ,""	  ,""      ,""        ,""    	 ,""      ,""      ,""    	,""        ,""        ,""      ,""      ,""      ,""		,""		   ,""		,""	  ,""     ,""		,""		,""		   ,""})
AADD(CPERG,{"03","Fornec Prod/Grupo?",""  ,""     	,"mv_ch3"	,"N"   ,01        ,0       	 ,0        ,"C"   ,""      ,"mv_par03","Prd.",""   		,"",""	   ,""   	,""      ,"Grupo" ,"" 		,""     	,""      ,""      ,""      ,""        ,""    	 ,""      ,""      ,""    	,""		   ,""        ,""      ,""      ,""      ,""		,""		   ,""		,""   ,""     ,""		,""		,""		   ,""})
AADD(CPERG,{"04","Aprova por Item/Sol?","",""     	,"mv_ch4"	,"N"   ,01        ,0       	 ,0        ,"C"   ,""      ,"mv_par04","Item",""   		,"",""     ,""      ,""      ,"Solic.","",""    ,""      	,""    	 ,""      ,""      ,""        ,""      	 ,""      ,""      ,""      ,""        ,""        ,""      ,""      ,""		 ,""		,""		   ,""		,""   ,""     ,""		,""		,""		   ,""})


	For i:=1 to Len(aRegs)
	If !dbSeek(CPERG+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

DbCloseArea("SX1")
RestArea(aAreaAnt)

Return