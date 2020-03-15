#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} COMWF002
//TODO Descrição: Envia Workflow de Aprovacao de Solicitacao de Compras.
				Para quando a aprovacao e feita por ITEM
	@author Igor Silva
	@since 06/03/2020
	@version 1.0
	@return ${return}, ${return_description}

	@type function
/*/
User Function COMWF002()

//*****************************
//	Declaração de Variaveis
//*****************************
Local cMvAtt 	:= GetMv("MV_WFHTML")
Local cAprov 	:= PswRet()[1][11]
Local cMailSup 	:= UsrRetMail(cAprov)
Local aMeses	:= {"Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"}
Local cMailId	:= ""							//ID do processo gerado.
Local cHostWF	:= "http://localhost:91/wf"		//URL configurado no ini para WF Link.
Local Step		:= 0
Local nMes		:= 0
Local nAno		:= 0

Local oHtml

cQuery := " SELECT C1_FILIAL, C1_NUM, C1_EMISSAO, C1_SOLICIT, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_DATPRF, C1_OBS, C1_CC, C1_CODAPRO, C1_QUJE, C1_LOCAL, B2_QATU, B1_EMIN, B1_QE, B1_UPRC"
cQuery += " FROM "+RetSqlName("SC1")+" AS C1"
//cQuery += " INNER JOIN SZ2010 AS Z2 ON C1_CC = Z2_COD"
cQuery += " INNER JOIN "+RetSqlName("SB2")+" AS B2 ON C1_PRODUTO = B2_COD AND C1_LOCAL = B2_LOCAL"
cQuery += " INNER JOIN "+RetSqlName("SB1")+" AS B1 ON C1_PRODUTO = B1_COD"
cQuery += " WHERE C1_NUM = '"+SC1->C1_NUM+"'"
cQuery += " AND C1_ITEM = '"+SC1->C1_ITEM+"'"

MemoWrit("COMWF002.sql",cQuery)
dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),"TRB", .F., .T.)

TcSetField("TRB","C1_EMISSAO","D")
TcSetField("TRB","C1_DATPRF","D")

COUNT TO nRec
//CASO TENHA DADOS
If nRec > 0
	
	dbSelectArea("TRB")
	TRB->(dbGoTop())
	
	cNumSc		:= TRB->C1_NUM
	cSolicit	:= TRB->C1_SOLICIT
	cItem		:= TRB->C1_ITEM
	dDtEmissao	:= DTOC(TRB->C1_EMISSAO)
	
	//***************************************************
	//	Muda o parametro para enviar no corpo do e-mail	
	//***************************************************
	PutMv("MV_WFHTML","T")
	
	oProcess:=TWFProcess():New("000004","WORKFLOW PARA APROVACAO DE SC")
	oProcess:NewTask('Inicio',"\workflow\koala\COMWF002.htm")
	oHtml   := oProcess:oHtml
	
	//***********************
	//	Dados do Cabecalho
	//***********************
	oHtml:ValByName("diasA"			, cDiasA)
	oHtml:ValByName("diasE"			, cDiasE)
	oHtml:ValByName("Num"		, TRB->C1_NUM				) //Numero da Cotacao
	oHtml:ValByName("Item1"		, TRB->C1_ITEM 				) //Item Cotacao
	oHtml:ValByName("CC"		, TRB->C1_CC				) //Centro de Custo
	//oHtml:ValByName("DescCC"	, TRB->Z2_NOME				) //Descricao Centro de Custo
	oHtml:ValByName("Req"	  	, TRB->C1_SOLICIT			) //Nome Requisitante
	oHtml:ValByName("Emissao"	, DTOC(TRB->C1_EMISSAO)		) //Data de Emissao Solicitacao
	//oHtml:ValByName("cAPROV"	, ""						) //Variavel que Retorna "Aprovado / Rejeitado"
	//oHtml:ValByName("cMOTIVO"	, ""						) //Variavel que Retorna o Motivo da Rejeicao
	
	//***********************
	//	Saldos em Estoque
	//***********************
	oHtml:ValByName("Item"		, TRB->C1_ITEM		   		) //Item Cotacao
	oHtml:ValByName("CodProd"	, TRB->C1_PRODUTO	   		) //Cod Produto
	oHtml:ValByName("Desc"		, TRB->C1_DESCRI			) //Descricao Produto
	oHtml:ValByName("SaldoAtu"	, TRANSFORM(TRB->B2_QATU  		, PesqPict("SB2","B2_QATU" ,12))	) //Saldo Atual Estoque
	oHtml:ValByName("EstMin"	, TRANSFORM(TRB->B1_EMIN		, PesqPict("SB1","B1_EMIN" ,12))	) //Ponto de Pedido
	oHtml:ValByName("QuantSol"	, TRANSFORM(TRB->C1_QUANT - TRB->C1_QUJE , PesqPict("SC1","C1_QUANT",12))) //Saldo da Solicitacao
	oHtml:ValByName("UM"		, TRANSFORM(TRB->C1_UM			, PesqPict("SC1","C1_UM"))			) //Unidade de Medida
	oHtml:ValByName("Local"		, TRANSFORM(TRB->C1_LOCAL		, PesqPict("SC1","C1_LOCAL"))		) //Armazem da Solicitacao
	oHtml:ValByName("QuantEmb"	, TRANSFORM(TRB->B1_QE			, PesqPict("SB1","B1_QE"   ,09))	) //Quantidade Por Embalagem
	oHtml:ValByName("UPRC"		, TRANSFORM(TRB->B1_UPRC		, PesqPict("SB1","B1_UPRC",12))		) //Ultimo Preco de Compra
	oHtml:ValByName("Lead" 		, TRANSFORM(CalcPrazo(TRB->C1_PRODUTO,TRB->C1_QUANT), "999")		) //Lead Time
	oHtml:ValByName("DataNec"	, If(Empty(TRB->C1_DATPRF),TRB->C1_EMISSAO,TRB->C1_DATPRF)			)//Data da Necessidade
	oHtml:ValByName("DataCom"	, SomaPrazo(If(Empty(TRB->C1_DATPRF),TRB->C1_EMISSAO,TRB->C1_DATPRF), -CalcPrazo(TRB->C1_PRODUTO,TRB->C1_QUANT)))// Data para Comprar
	oHtml:ValByName("Obs"		, TRANSFORM(TRB->C1_OBS , "@!")										) //Observacao da Cotacao
	
	//***********************
	//	Ordens de Produção
	//***********************
	oHtml:ValByName("op1.OP"		, {})//Coloca em Branco para
	oHtml:ValByName("op1.Prod"		, {})//caso nao tenha nenhuma OP
	oHtml:ValByName("op1.Ini"		, {})
	oHtml:ValByName("op1.QtdOp"		, {})
	oHtml:ValByName("op2.OP"		, {})
	oHtml:ValByName("op2.Prod"		, {})
	oHtml:ValByName("op2.Ini"		, {})
	oHtml:ValByName("op2.QtdOp"		, {})
	oHtml:ValByName("op3.OP"		, {})
	oHtml:ValByName("op3.Prod"		, {})
	oHtml:ValByName("op3.Ini"		, {})
	oHtml:ValByName("op3.QtdOp"		, {})
	
	//Query busca as OPs do produto
	cQuery1 := " SELECT D4_OP, D4_DATA, D4_QUANT, C2_PRODUTO"
	cQuery1 += " FROM "+RetSqlName("SD4")+" AS D4"
	cQuery1 += " INNER JOIN "+RetSqlName("SC2")+" AS C2"
	cQuery1 += " ON SUBSTRING(D4_OP,1,6) = C2_NUM"
	cQuery1 += " AND SUBSTRING(D4_OP,7,2) = C2_ITEM"
	cQuery1 += " AND SUBSTRING(D4_OP,9,3) = C2_SEQUEN"
	cQuery1 += " WHERE D4_COD = '"+TRB->C1_PRODUTO+"'"
	cQuery1 += " AND D4_QUANT > 0"
	cQuery1 += " AND D4.D_E_L_E_T_ <> '*'"
	cQuery1 += " AND C2.D_E_L_E_T_ <> '*'"
	cQuery1 += " ORDER BY D4_DATA"
	
	MemoWrit("COMWF002a.sql",cQuery1)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery1),"TRB1", .F., .T.)
	
	TcSetField("TRB1","D4_DATA","D")
	
	COUNT TO nRec1
	//CASO TENHA DADOS
	If nRec1 > 0
		
		dbSelectArea("TRB1")
		TRB1->(dbGoTop())
		
		While !EOF()
			aadd(oHtml:ValByName("op1.OP")		, TRB1->D4_OP			) //Numero da OP 1
			aadd(oHtml:ValByName("op1.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 1
			aadd(oHtml:ValByName("op1.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 1
			aadd(oHtml:ValByName("op1.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 1
			TRB1->(dbSkip())
			aadd(oHtml:ValByName("op2.OP")		, TRB1->D4_OP			) //Numero da OP 2
			aadd(oHtml:ValByName("op2.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 2
			aadd(oHtml:ValByName("op2.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 2
			aadd(oHtml:ValByName("op2.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 2
			TRB1->(dbSkip())
			aadd(oHtml:ValByName("op3.OP")		, TRB1->D4_OP			) //Numero da OP 3
			aadd(oHtml:ValByName("op3.Prod")	, TRB1->C2_PRODUTO		) //Produto a Ser Produzido OP 3
			aadd(oHtml:ValByName("op3.Ini")		, DTOC(TRB1->D4_DATA)	) //Data da OP 3
			aadd(oHtml:ValByName("op3.QtdOp")	, TRANSFORM(TRB1->D4_QUANT , PesqPict("SD4","D4_QUANT",12))	) //Quantidade OP 3
			TRB1->(dbSkip())
		End
		
	Else
		
		aadd(oHtml:ValByName("op1.OP")		, "")
		aadd(oHtml:ValByName("op1.Prod")	, "")
		aadd(oHtml:ValByName("op1.Ini")		, "")
		aadd(oHtml:ValByName("op1.QtdOp")	, "")
		aadd(oHtml:ValByName("op2.OP")		, "")
		aadd(oHtml:ValByName("op2.Prod")	, "")
		aadd(oHtml:ValByName("op2.Ini")		, "")
		aadd(oHtml:ValByName("op2.QtdOp")	, "")
		aadd(oHtml:ValByName("op3.OP")		, "")
		aadd(oHtml:ValByName("op3.Prod")	, "")
		aadd(oHtml:ValByName("op3.Ini")		, "")
		aadd(oHtml:ValByName("op3.QtdOp")	, "")
	EndIf
	TRB1->(dbCloseArea())
	
	//*****************************
	//	Consumo Ultimos 12 Meses
	//*****************************
	//Query busca Consumo do produto
	cQuery2 := " SELECT *"
	cQuery2 += " FROM "+RetSqlName("SB3")
	cQuery2 += " WHERE B3_COD = '"+TRB->C1_PRODUTO+"'"
	cQuery2 += " AND D_E_L_E_T_ <> '*'"
	
	MemoWrit("COMWF002b.sql",cQuery2)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery2),"TRB2", .F., .T.)
	
	COUNT TO nRec2
	//CASO TENHA DADOS
	If nRec2 > 0
		
		dbSelectArea("TRB2")
		TRB2->(dbGoTop())
		
		cMeses := Space(5)
		nAno := YEAR(dDataBase)
		nMes := MONTH(dDataBase)
		aOrdem := {}
		
		For j := nMes To 1 Step -1 //Preenche Meses Anteriores do Ano Atual
			cMeses += aMeses[j]+"/"+Substr(Str(nAno,4),3,2)
			AADD(aOrdem,j)
		Next j
		
		nAno-- //Volta para Ano Anterior
		
		For j := 12 To nMes+1 Step -1 //Preenche Meses Finais do Ano Anterior
			cMeses += aMeses[j]+"/"+Substr(Str(nAno,4),3,2)
			AADD(aOrdem,j)
		Next j
		
		For j :=1 to 12 //Preenche as variaveis do HTML
			cVarMes := "Mes"+AllTrim(Str(j))
			oHtml:ValByName(cVarMes		, SubStr(cMeses,(j*6),6)) // Meses de Consumo
		Next j
		
		For j := 1 To Len(aOrdem)
			cMes    := StrZero(aOrdem[j],2)
			cCampos := "TRB2->B3_Q"+cMes
			oHtml:ValByName("CMes"+AllTrim(Str(j))	, TRANSFORM(&cCampos , PesqPict("SB3","B3_Q01",9))) //Valor de Consumo nos Meses
		Next j
		
		oHtml:ValByName("MedC"		, TRANSFORM(TRB2->B3_MEDIA, PesqPict("SB3","B3_MEDIA",8))) //Media de Consumo
		
	Else //Caso nao tenha dados
		
		oHtml:ValByName("MedC"		, "")
		For m := 1 To 12
			oHtml:ValByName("CMes"+AllTrim(Str(m))	, "")
			oHtml:ValByName("Mes"+AllTrim(Str(m))	, "")
		Next m
	EndIf
	TRB2->(dbCloseArea())
	
	//*****************************
	//	Ultimos Pedidos de Compra
	//*****************************
	oHtml:ValByName("it.NumP"			, {})
	oHtml:ValByName("it.ItemP"			, {})
	oHtml:ValByName("it.CodP"			, {})
	oHtml:ValByName("it.LjP"			, {})
	oHtml:ValByName("it.NomeP"			, {})
	oHtml:ValByName("it.QtdeP"			, {})
	oHtml:ValByName("it.UMP"			, {})
	oHtml:ValByName("it.VlrUnP"			, {})
	oHtml:ValByName("it.VlrTotP"		, {})
	oHtml:ValByName("it.EmiP"			, {})
	oHtml:ValByName("it.NecP"			, {})
	oHtml:ValByName("it.PraP"			, {})
	oHtml:ValByName("it.CondP"			, {})
	oHtml:ValByName("it.QtdeEntP"		, {})
	oHtml:ValByName("it.SalP"			, {})
	oHtml:ValByName("it.EliP"			, {})
	
	//Query busca Pedidos do Produto
	cQuery3 := " SELECT C7_NUM, C7_ITEM, C7_FORNECE, C7_LOJA, A2_NOME, C7_QUANT, C7_UM, C7_PRECO, C7_TOTAL, C7_EMISSAO, C7_DATPRF, C7_COND, C7_QUJE, C7_RESIDUO"
	cQuery3 += " FROM "+RetSqlName("SC7")+" AS C7"
	cQuery3 += " INNER JOIN "+RetSqlName("SA2")+" AS A2 ON A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA"
	cQuery3 += " WHERE C7_FILIAL = '"+TRB->C1_FILIAL+"' AND C7_PRODUTO = '"+TRB->C1_PRODUTO+"'"
	cQuery3 += " AND C7.D_E_L_E_T_ <> '*'"
	cQuery3 += " AND A2.D_E_L_E_T_ <> '*'"
	cQuery3 += " ORDER BY C7_EMISSAO DESC"
	
	MemoWrit("COMWF002c.sql",cQuery3)
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery3),"TRB3", .F., .T.)
	
	TcSetField("TRB3","C7_EMISSAO","D")
	TcSetField("TRB3","C7_DATPRF","D")
	
	COUNT TO nRec3
	//CASO TENHA DADOS
	If nRec3 > 0
		
		dbSelectArea("TRB3")
		TRB3->(dbGoTop())
		
		nContador := 0
		
		While !TRB3->(EOF())
			
			nContador++
			If nContador > 03 //Numero de Pedidos
				Exit
			EndIf
			
			aadd(oHtml:ValByName("it.NumP")			, TRB3->C7_NUM		)
			aadd(oHtml:ValByName("it.ItemP")		, TRB3->C7_ITEM		)
			aadd(oHtml:ValByName("it.CodP")			, TRB3->C7_FORNECE	)
			aadd(oHtml:ValByName("it.LjP")			, TRB3->C7_LOJA		)
			aadd(oHtml:ValByName("it.NomeP")		, TRB3->A2_NOME		)
			aadd(oHtml:ValByName("it.QtdeP")		, TRANSFORM(TRB3->C7_QUANT , PesqPict("SC7","C7_QUANT",14))	)
			aadd(oHtml:ValByName("it.UMP")			, TRB3->C7_UM		)
			aadd(oHtml:ValByName("it.VlrUnP")		, TRANSFORM(TRB3->C7_PRECO, PesqPict("SC7","c7_preco",14))	)
			aadd(oHtml:ValByName("it.VlrTotP")		, TRANSFORM(TRB3->C7_TOTAL, PesqPict("SC7","c7_total",14))	)
			aadd(oHtml:ValByName("it.EmiP")			, DTOC(TRB3->C7_EMISSAO))
			aadd(oHtml:ValByName("it.NecP")			, DTOC(TRB3->C7_DATPRF)	)
			aadd(oHtml:ValByName("it.PraP")			, TRANSFORM(Val(DTOC(TRB3->C7_DATPRF))-Val(DTOC(TRB3->C7_EMISSAO)), "999"))
			aadd(oHtml:ValByName("it.CondP")		, TRB3->C7_COND		)
			aadd(oHtml:ValByName("it.QtdeEntP")		, TRANSFORM(TRB3->C7_QUJE, PesqPict("SC7","C7_QUJE",14))		)
			aadd(oHtml:ValByName("it.SalP")			, TRANSFORM(If(Empty(TRB3->C7_RESIDUO),TRB3->C7_QUANT-TRB3->C7_QUJE,0), PesqPict("SC7","C7_QUJE",14)))
			aadd(oHtml:ValByName("it.EliP")			, If(Empty(TRB3->C7_RESIDUO),'Não','Sim'))
			
			TRB3->(dbSkip())
		End
		
	Else //Caso nao tenha dados
		
		aadd(oHtml:ValByName("it.NumP")			, "")
		aadd(oHtml:ValByName("it.ItemP")		, "")
		aadd(oHtml:ValByName("it.CodP")			, "")
		aadd(oHtml:ValByName("it.LjP")			, "")
		aadd(oHtml:ValByName("it.NomeP")		, "")
		aadd(oHtml:ValByName("it.QtdeP")		, "")
		aadd(oHtml:ValByName("it.UMP")			, "")
		aadd(oHtml:ValByName("it.VlrUnP")		, "")
		aadd(oHtml:ValByName("it.VlrTotP")		, "")
		aadd(oHtml:ValByName("it.EmiP")			, "")
		aadd(oHtml:ValByName("it.NecP")			, "")
		aadd(oHtml:ValByName("it.PraP")			, "")
		aadd(oHtml:ValByName("it.CondP")		, "")
		aadd(oHtml:ValByName("it.QtdeEntP")		, "")
		aadd(oHtml:ValByName("it.SalP")			, "")
		aadd(oHtml:ValByName("it.EliP")			, "")
		
	EndIf
	TRB3->(dbCloseArea())
	
	//*************************
	//	Ultimos Fornecedores
	//*************************
	
	oHtml:ValByName("it1.CodF"			, {})
	oHtml:ValByName("it1.LjF"			, {})
	oHtml:ValByName("it1.NomeF"			, {})
	oHtml:ValByName("it1.TelF"			, {})
	oHtml:ValByName("it1.ContF"			, {})
	oHtml:ValByName("it1.FaxF"			, {})
	oHtml:ValByName("it1.UlComF"		, {})
	oHtml:ValByName("it1.MunicF"		, {})
	oHtml:ValByName("it1.UFF"			, {})
	oHtml:ValByName("it1.RisF"			, {})
	oHtml:ValByName("it1.CodForF"		, {})
	
	If mv_par03 == 1 // Amarracao por Produto
		
		//Query busca Fornecedores do Produto
		cQuery4 := " SELECT A5_FORNECE, A5_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO, A5_CODPRF"
		cQuery4 += " FROM " + RetSqlName("SA5") + " AS A5"
		cQuery4 += " INNER JOIN " + RetSqlName("SA2") + " A2 ON A5_FORNECE = A2_COD AND A5_LOJA = A2_LOJA"
		cQuery4 += " WHERE A5_PRODUTO = '"+TRB->C1_PRODUTO+"'"
		cQuery4 += " AND A5.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " order by  A2_ULTCOM DESC"
		
		MemoWrit("COMWF002d.sql",cQuery4)
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRB4", .F., .T.)
		
		TcSetField("TRB4","A2_ULTCOM","D")
		
		COUNT TO nRec4
		//CASO TENHA DADOS
		If nRec4 > 0
			
			dbSelectArea("TRB4")
			TRB4->(dbGoTop())
			
			nContador := 0
			
			While !TRB4->(EOF())
				
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				
				aadd(oHtml:ValByName("it1.CodF")		, TRB4->A5_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRB4->A5_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRB4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRB4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRB4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRB4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRB4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRB4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRB4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRB4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, TRB4->A5_CODPRF	) //Codigo no Forncedor
				
				TRB4->(dbSkip())
			End
			
		Else //Caso nao tenha dados
			
			aadd(oHtml:ValByName("it1.CodF")		, ""	) //Codigo do Fornecedor
			aadd(oHtml:ValByName("it1.LjF")			, ""	) //Codigo da Loja
			aadd(oHtml:ValByName("it1.NomeF")		, ""	) //Nome do Fornecedor
			aadd(oHtml:ValByName("it1.TelF")		, ""	) //Telefone do Fornecedor
			aadd(oHtml:ValByName("it1.ContF")		, ""	) //Contato no Fornecedor
			aadd(oHtml:ValByName("it1.FaxF")		, ""	) //Fax no Fornecedor
			aadd(oHtml:ValByName("it1.UlComF")		, ""	) //Ultima Compra com o Fornecedor
			aadd(oHtml:ValByName("it1.MunicF")		, ""	) //Municipio do Fornecedor
			aadd(oHtml:ValByName("it1.UFF")			, ""	) //Estado do Fornecedor
			aadd(oHtml:ValByName("it1.RisF")		, ""	) //Risco do Fornecedor
			aadd(oHtml:ValByName("it1.CodForF")		, ""	) //Codigo no Forncedor
			
		EndIf
		TRB4->(dbCloseArea())
		
	Else
		
		//Query busca Fornecedores do Grupo de Produtos
		cQuery4 := " SELECT AD_FORNECE, AD_LOJA, A2_NOME, A2_TEL, A2_CONTATO, A2_FAX, A2_ULTCOM, A2_MUN, A2_EST, A2_RISCO"
		cQuery4 += " FROM "+RetSqlName("SB1")+" AS B1"
		cQuery4 += " INNER JOIN " + RetSqlName("SAD")+ " AS AD ON B1_GRUPO = AD_GRUPO"
		cQuery4 += " INNER JOIN " + RetSqlName("SA2") + " AS A2 ON AD_FORNECE = A2_COD AND AD_LOJA = A2_LOJA"
		cQuery4 += " WHERE B1_COD = '"+TRB->C1_PRODUTO+"'"
		cQuery4 += " AND AD.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND A2.D_E_L_E_T_ <> '*'"
		cQuery4 += " AND B1.D_E_L_E_T_ <> '*'"
		cQuery4 += " ORDER BY  A2_ULTCOM DESC"
		
		MemoWrit("COMWF002d.sql",cQuery4)
		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery4),"TRB4", .F., .T.)
		
		TcSetField("TRB4","A2_ULTCOM","D")
		
		COUNT TO nRec4
		//CASO TENHA DADOS
		If nRec4 > 0
			
			dbSelectArea("TRB4")
			TRB4->(dbGoTop())
			
			nContador := 0
			
			While !TRB4->(EOF())
				
				nContador++
				If nContador > 03 //Numero de Fornecedores
					Exit
				EndIf
				
				aadd(oHtml:ValByName("it1.CodF")		, TRB4->AD_FORNECE	) //Codigo do Fornecedor
				aadd(oHtml:ValByName("it1.LjF")			, TRB4->AD_LOJA		) //Codigo da Loja
				aadd(oHtml:ValByName("it1.NomeF")		, TRB4->A2_NOME		) //Nome do Fornecedor
				aadd(oHtml:ValByName("it1.TelF")		, TRB4->A2_TEL		) //Telefone do Fornecedor
				aadd(oHtml:ValByName("it1.ContF")		, TRB4->A2_CONTATO	) //Contato no Fornecedor
				aadd(oHtml:ValByName("it1.FaxF")		, TRB4->A2_FAX		) //Fax no Fornecedor
				aadd(oHtml:ValByName("it1.UlComF")		, DTOC(TRB4->A2_ULTCOM)	) //Ultima Compra com o Fornecedor
				aadd(oHtml:ValByName("it1.MunicF")		, TRB4->A2_MUN		) //Municipio do Fornecedor
				aadd(oHtml:ValByName("it1.UFF")			, TRB4->A2_EST		) //Estado do Fornecedor
				aadd(oHtml:ValByName("it1.RisF")		, TRB4->A2_RISCO	) //Risco do Fornecedor
				aadd(oHtml:ValByName("it1.CodForF")		, ""				) //Codigo no Forncedor
				TRB4->(dbSkip())
			End
			
		Else //Caso nao tenha dados
			
			aadd(oHtml:ValByName("it1.CodF")		, ""	) //Codigo do Fornecedor
			aadd(oHtml:ValByName("it1.LjF")			, ""	) //Codigo da Loja
			aadd(oHtml:ValByName("it1.NomeF")		, ""	) //Nome do Fornecedor
			aadd(oHtml:ValByName("it1.TelF")		, ""	) //Telefone do Fornecedor
			aadd(oHtml:ValByName("it1.ContF")		, ""	) //Contato no Fornecedor
			aadd(oHtml:ValByName("it1.FaxF")		, ""	) //Fax no Fornecedor
			aadd(oHtml:ValByName("it1.UlComF")		, ""	) //Ultima Compra com o Fornecedor
			aadd(oHtml:ValByName("it1.MunicF")		, ""	) //Municipio do Fornecedor
			aadd(oHtml:ValByName("it1.UFF")			, ""	) //Estado do Fornecedor
			aadd(oHtml:ValByName("it1.RisF")		, ""	) //Risco do Fornecedor
			aadd(oHtml:ValByName("it1.CodForF")		, ""	) //Codigo no Forncedor
			
		EndIf
		TRB4->(dbCloseArea())
		
	EndIf
	
	//**********************************
	//	Funcoes para Envio do Workflow
	//**********************************
	//envia o e-mail
	cUser 			  := Subs(cUsuario,7,15)
	oProcess:ClientName(cUser)
	oProcess:cTo    	:= "koala"
	oProcess:cSubject := "Aprovação de SC N°: "+cNumSc+" Item: "+cItem+" - De: "+cSolicit
	//oProcess:cBody    := ""
	oProcess:bReturn  := "U_COMWF02a()"

	cMailID := oProcess:Start()

	
	PutMv("MV_WFHTML",cMvAtt)
	
	//*********************************************************
	//	Inicia o processo de enviar link no corpo do e-mail
	//*********************************************************
	
	oProcess:newtask('000005', '\workflow\koala\COMWFLINK002.HTM')  //Inicio uma nova Task com um HTML Simples
  	oProcess:ohtml:valbyname('proc_link',cHostWF+'/workflow/messenger/'+'/emp'+ cEmpAnt + '/koala/' + cMailId + '.HTM' ) //Defino o Link onde foi gravado o HTML pelo Workflow,abaixo do diretório do usuário definido em cTo do processo acima.
		                                                                                        
  	oHtml:ValByName("cNumSc"			, cNumSc)
	oHtml:ValByName("cSolicitante"		, cSolicit)
	oHtml:ValByName("cDtEmissao"		, dDtEmissao)
  
	oProcess:cTo    	:= cMailSup //E-mail do aprovador
	oProcess:cBCC     	:= "igor-d-silva@hotmail.com" //Cópia
	oProcess:cSubject  	:= "Aprovação de SC - "+cNumSc+" - De: "+cSolicit

    oProcess:Start()
    oProcess:Free()
    oProcess:= Nil
    
//Grava campo C1_WFENVIO
DbSelectArea("SC1")
	RecLock("SC1", .T.)		
		SC1->C1_WFENVIO := .T.
	MsUnLock() // Confirma e finaliza a operação
SC1->(DbCloseArea())
	
Else
	MsgStop("Foi encontrado um problema na Geração do E-Mail de Aprovação. Favor avisar o Depto de Informática. NREC =","ATENÇÃO!")
EndIf

TRB->(dbCloseArea())

Return