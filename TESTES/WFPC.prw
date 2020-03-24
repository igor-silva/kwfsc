#INCLUDE 'PROTHEUS.CH'

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³P.ENTRADA ³MT120FIM  ³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Ponto de entrada localizado no final do processo de gravacao³±±
±±³          ³do pedido de compra. Sera utilizado para montagem e envio do³±±
±±³          ³processo de workflow                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function WFPC()

	Local nOpc      := 3
	Local cNumPC    := SC7->C7_NUM
	Local lOk       := .T.
	
	
	If nOpc == 3 .And. lOk 
		MsgRun('Montando processo de Workflow...', 'Aguarde...', {|| U_WFPCSend(cNumPC)})
	EndIf

	//U_WFPCSend(SC7->C7_NUM)
	
Return()	


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³FUNCAO    ³WFPCSend  ³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Funcao responsavel pelo montagem e envio do processo de     ³±±
±±³          ³workflow                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function WFPCSend(cNumPC)
	Local oProcess  := NIL
	Local cSimbMoed := SuperGetMV('MV_SIMB' + Alltrim(Str(SC7->C7_MOEDA)), .F., 'R$') + ' '
	Local cMailId   := ''
	Local cUrl      := ''
	Local cHTTPSrv  := ''
	Local cPastaHTM := ''
	Local cMailApr  := ''
	
	Local cAliasQry := ''
	Local aDoctos   := {}
	Local nCount    := 0
	
	Local aArea     := GetArea()
	Local aAreaSA2  := SA2->(GetArea())
	Local aAreaSB1  := SB1->(GetArea())
	Local aAreaSC7  := SC7->(GetArea())
	
	
	SC7->(DbSetOrder(1))
	If SC7->(DbSeek(xFilial('SC7')+cNumPC))
		// ----------------------------------------
		// Verifica o controle de alcadas, somente
		// para Pedidos de Compra:
		// ---------------------------------------
		cAliasQry := GetNextAlias()
		BeginSQl Alias cAliasQry
			SELECT 	SCR.CR_STATUS, SCR.R_E_C_N_O_ nRecSCR
			FROM 	%Table:SCR% SCR
			WHERE 	SCR.CR_FILIAL =  %xFilial:SCR% AND
					SCR.CR_NUM    =  %Exp:SC7->C7_NUM% AND
					SCR.CR_TIPO   =  %Exp:'PC'% AND
					SCR.CR_WF     =  %Exp:Space(Len(SCR->CR_WF))% AND
					SCR.%NotDel%
			ORDER 
			BY 		SCR.CR_NUM, 
					SCR.CR_NIVEL, 
					SCR.R_E_C_N_O_
		EndSQL
		(cAliasQry)->(DBEval({|| If(CR_STATUS $ '02|04', AAdd(aDoctos, {CR_STATUS, nRecSCR}), NIL)},, {|| !Eof()}))
		(cAliasQry)->(DbCloseArea())
	
		For nCount := 1 To Len(aDoctos)
			SCR->(DbGoTo(aDoctos[nCount, 2]))
			cDocto := SCR->CR_NUM
			PswOrder(1)
			If PswSeek(SCR->CR_USER) .And. !Empty(PswRet()[1,14])
				cMailApr := AllTrim(PswRet()[1,14])
	
				// ---------------------------------------------------------
				// Criacao do objeto TWFProcess, responsavel 
				// pela inicializacao do processo de Workflow
				// ---------------------------------------------------------
				oProcess := TWFProcess():New('APR_PC', 'Criacao do Processo - Aprovacao de Pedidos')
	
				// ---------------------------------------------------------
				// Criacao de uma tarefa de workflow. Podem 
				// existir varias tarefas. Para cada tarefa, 
				// deve-se informar um nome e o HTML envolvido
				// ---------------------------------------------------------
				oProcess:NewTask('WFA010', '\WORKFLOW\WFA010.HTML')
	
				// ---------------------------------------------------------
				// Determinacao da funcao que realiza o processamento
				// do retorno do workflow
				// ---------------------------------------------------------
				oProcess:bReturn := 'U_WFPCRet()'
	
				// ---------------------------------------------------------
				// Tratamento do timeout. Este tratamento tem o objetivo
				// de determinar o tempo maximo para processamento do retorno
				// ---------------------------------------------------------
				oProcess:bTimeOut := {{'U_PCTimeOut()', 0, 0, 5 }}
	
				// ---------------------------------------------------------
				// Realiza o preenchimento do HTML:
				// ---------------------------------------------------------
				SC7->(DbSetOrder(1))
				SC7->(DbSeek(xFilial('SC7')+cNumPC))
	
				SA2->(DbSetOrder(1))
				SA2->(DbSeek(xFilial('SA2')+SC7->(C7_FORNECE+C7_LOJA)))
	
				SE4->(DbSetOrder(1))
				SE4->(DbSeek(xFilial('SE4')+SC7->C7_COND))
	
				oProcess:oHtml:ValByName('cNumPed'		, SC7->C7_NUM)
				oProcess:oHtml:ValByName('dEmissao'		, SC7->C7_EMISSAO)
				oProcess:oHtml:ValByName('cCodFor'		, SC7->(C7_FORNECE + '/' + C7_LOJA))
				oProcess:oHtml:ValByName('cNomFor' 		, SA2->A2_NOME)
				oProcess:oHtml:ValByName('cCodAprov'	, SCR->CR_USER)
				oProcess:oHtml:ValByName('cCondPagto'	, '(' + SC7->C7_COND + ') ' + SE4->E4_DESCRI)
		
				While !SC7->(Eof()) .And.; 
						SC7->(C7_FILIAL+C7_NUM) == xFilial('SC7')+cNumPC
	
					AAdd(oProcess:oHtml:ValByName('PED.cItem')		, SC7->C7_ITEM)
					AAdd(oProcess:oHtml:ValByName('PED.cCodPro')	, SC7->C7_PRODUTO)
					AAdd(oProcess:oHtml:ValByName('PED.cDesPro')	, SC7->C7_DESCRI)
					AAdd(oProcess:oHtml:ValByName('PED.cUnidMed')	, SC7->C7_UM)
					AAdd(oProcess:oHtml:ValByName('PED.nQtde')		, Transform(SC7->C7_QUANT, PesqPict('SC7', 'C7_QUANT')))
					AAdd(oProcess:oHtml:ValByName('PED.nValUnit')	, cSimbMoed + Transform(SC7->C7_PRECO, PesqPict('SC7', 'C7_PRECO')))
					AAdd(oProcess:oHtml:ValByName('PED.nValTot')	, cSimbMoed + Transform(SC7->C7_TOTAL, PesqPict('SC7', 'C7_TOTAL')))
					AAdd(oProcess:oHtml:ValByName('PED.dDtEntr')	, SC7->C7_DATPRF)
			
					SC7->(DbSkip())
				End
		
				// ---------------------------------------------------------
				// Realiza a gravacao do processo de workflow.
				// Este processo sera gravado no servidor para
				// que seja acessado posteriormente via link 
				// enviado no e-mail de notificacao do processo
				// ---------------------------------------------------------
				cPastaHTM    := 'PROCESSOS'
				oProcess:cTo := cPastaHTM
	
				// ---------------------------------------------------------
				// Tratamento da rastreabilidade do workflow
				// 1o. passo: Envio do e-mail:
				// ---------------------------------------------------------
				//RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode,'10001')  
	
				// ---------------------------------------------------------
				// Reposiciona o SC7 para gravacao do processo de 
				// workflow no pedido de compras:
				// ---------------------------------------------------------
				SC7->(DbSeek(xFilial('SC7')+cNumPC))
				While !SC7->(Eof()) .And.; 
						SC7->(C7_FILIAL+C7_NUM) == xFilial('SC7')+cNumPC
		
					RecLock('SC7', .F.)
					SC7->C7_WFID := oProcess:fProcessID
					SC7->(MsUnLock())
	
					SC7->(DbSkip())
				End
	
				// ---------------------------------------------------------
				// Inicia o processo de workflow e 
				// guarda o Id do processo para montagem
				// do e-mail de link:
				// ---------------------------------------------------------
				cMailId := oProcess:Start()
	
				// ---------------------------------------------------------
			    // Nova tarefa para envio do e-mail com
			    // o link do processo:
				// ---------------------------------------------------------
				oProcess:NewTask('WFA020', '\WORKFLOW\WFLinkPC.HTML')
	
				// ---------------------------------------------------------
				// Atualiza os dados no HTML referente 
				// a mensagem com o link:
				// ---------------------------------------------------------
				cHTTPSrv := 'localhost:91/wf/'
				cUrl     := 'http://' + cHttpSrv + 'workflow/messenger/emp' + cEmpAnt + '/' + cPastaHTM + '/' + cMailId + '.htm'
				oProcess:oHtml:ValByName('cLink', cUrl)
		
				// ---------------------------------------------------------
				// Determina o destinatario do e-mail de
				// aprovacao:
				// ---------------------------------------------------------
				oProcess:cTo := cMailApr
				oProcess:cCC := ''
				oProcess:cBCC:= ''
	
				// ---------------------------------------------------------
				// Titulo para o email:
				// ---------------------------------------------------------
				
				oProcess:cSubject := 'Aprovacao de Pedido de Compra'
					
				// ---------------------------------------------------------
				// Envia o e-mail com link para aprovacao
				// ---------------------------------------------------------
				oProcess:Start()
	
				// ---------------------------------------------------------
				// Libera Objeto
				// ---------------------------------------------------------
				oProcess :Free()
				oProcess := NIL
			EndIf
		Next nCount
	Endif  
	
	RestArea(aArea)
	RestArea(aAreaSA2)
	RestArea(aAreaSB1)
	RestArea(aAreaSC7)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³FUNCAO    ³WFPCRet   ³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Funcao responsavel pelo tratamento do retorno do processo de³±±
±±³          ³workflow                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function WFPCRet(oProcess)
	Local cNumPC    := ''
	Local cNumSCR   := ''
	Local cCodAprov := ''
	Local lAprovado := .F.
	Local lContinua := .T.
	Local aRetSaldo := {}
	Local nTotal    := 0
	Local lLiberou  := .F.
	
	Local aArea     := GetArea()
	Local aAreaSC7  := {}
	Local aAreaSCR  := SCR->(GetArea())
	
	// -----------------------------------------------
	// Obtem os dados do formulario HTML para
	// tratamento do retorno:
	// -----------------------------------------------
	cNumPC     := oProcess:oHtml:RetByName('cNumPed')
	cNumSCR    := PadR(oProcess:oHtml:RetByName('cNumPed'),Len(SCR->CR_NUM))
	cObserv    := oProcess:oHtml:RetByName('cObsApr')
	cCodAprov  := oProcess:oHtml:RetByName('cCodAprov')
	lAprovado  := oProcess:oHtml:RetByName('Aprovacao') == 'S'
	
	// -----------------------------------------------
	// Posiciona no Documento de Alcada
	// -----------------------------------------------
	SCR->(DbSetOrder(2)) //-- CR_FILIAL+CR_TIPO+CR_NUM+CR_USER
	If SCR->(DbSeek(xFilial('SCR') + 'PC' + cNumSCR + cCodAprov))
	
		// -----------------------------------------------
		// Posiciona nas tabelas auxiliares
		// -----------------------------------------------
		SAK->( DbSetOrder(1) )
		SAK->( DbSeek(xFilial("SAK")+cCodAprov))
	
		SC7->( DbSetOrder(1) )
		If SC7->( DbSeek(xFilial("SC7")+cNumPC))
			cObsApr := SC7->C7_OBSAPR
			cObsApr += Chr(10)+Chr(13)
			cObsApr += '[OBSERVACOES REALIZADAS PELO APROVADOR: ' + UsrRetName(SCR->CR_USER) + ']' + Chr(10)+Chr(13)
			cObsApr += cObserv
	
			aAreaSC7 := SC7->(GetArea())
			While !SC7->(Eof()) .And.; 
					SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7")+cNumPC
	
				RecLock('SC7', .F.)
				SC7->C7_OBSAPR := /*cObsApr*/'[OBSERVACOES REALIZADAS PELO APROVADOR: ' + UsrRetName(SCR->CR_USER) + ']' + Alltrim(cObserv) + Chr(10)+Chr(13)
				SC7->(MsUnLock())
				SC7->(DbSkip())
	
			End
			RestArea(aAreaSC7)
		EndIf	
	
		SAL->( DbSetOrder(3) )
		SAL->( DbSeek(xFilial("SAL")+SC7->C7_APROV+SAK->AK_COD) )
	
		// -----------------------------------------------
		// Avalia o Status do Documento a ser liberado
		// -----------------------------------------------
		If lContinua .And. !Empty(SCR->CR_DATALIB) .And. SCR->CR_STATUS$'03|05'
			Conout('Este pedido ja foi liberado anteriormente. Somente os pedidos que estao aguardando liberacao poderao ser liberados.')
			lContinua := .F.
	
		ElseIf lContinua .And. SCR->CR_STATUS$'01'
			Conout('Esta operação não poderá ser realizada pois este registro se encontra bloqueado pelo sistema (aguardando outros niveis)')
			lContinua := .F.
	
		EndIf
	
		If lContinua
			// ---------------------------------------------------------
			// Inicializa a gravacao dos lancamentos do SIGAPCO
			// ---------------------------------------------------------
			PcoIniLan("000055")
		
			// ---------------------------------------------------------
			// Avalia liberacao do DOcumento pelo PCO
			// ---------------------------------------------------------
			If !ValidPcoLan()
				Conout('Bloqueio de Liberacao pelo PCO.')
				lContinua := .F.
	
			EndIf
	
			// ---------------------------------------------------------
			// Analisa o Saldo do Aprovador
			// ---------------------------------------------------------
			If lContinua .And. SAL->AL_LIBAPR == 'A'
				aRetSaldo  := MaSalAlc(cCodAprov,dDataBase)
				nTotal     := xMoeda(SCR->CR_TOTAL,SCR->CR_MOEDA,aRetSaldo[2],SCR->CR_EMISSAO,,SCR->CR_TXMOEDA)
				If (aRetSaldo[1] - nTotal) < 0
					Conout('Saldo na data insuficiente para efetuar a liberacao do pedido. Verifique o saldo disponivel para aprovacao na data e o valor total do pedido.')
					lContinua := .F.
				EndIf
			EndIf
		
			If lContinua
				Begin Transaction
					// ---------------------------------------------------------
					// Executa a liberacao ou rejeicao
					// do Pedido de Compra.
					// ---------------------------------------------------------
					lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SC7->C7_APROV,,,,,cObserv},dDataBase,If(lAprovado,4,6))
		
					If Empty(SCR->CR_DATALIB) //-- Verifica se Aprovou se liberou o Documento
						Conout('Nao foi possivel realizar a liberacao do Documento via WorkFlow. Tente realizar a liberacao manual.')
						lContinua := .F.
					EndIf
	
					If lContinua
						If lLiberou //-- Verifica se todos os niveis ja foram aprovados
							// ---------------------------------------------------------
							// Grava os lancamentos nas contas orcamentarias SIGAPCO
							// ---------------------------------------------------------
							PcoDetLan("000055","02","MATA097")
	
							While SC7->(!Eof()) .And.; 
									SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+PadR(SCR->CR_NUM,Len(SC7->C7_NUM))
	
								Reclock("SC7",.F.)
								SC7->C7_CONAPRO := "L" //-- Atualiza o status (Liberado) no Pedido de Compra
								SC7->(MsUnlock())
	
								// ---------------------------------------------------------
								// Grava os lancamentos nas contas orcamentarias SIGAPCO
								// ---------------------------------------------------------
								PcoDetLan("000055","01","MATA097")
								SC7->( dbSkip() )
							End
	
							SC7->(DbSetOrder(1))
							SC7->(DbSeek(xFilial("SC7")+cNumPC))
	
						Else
							If SCR->CR_STATUS == '04'	//-- Se Rejeitado
								Conout('O pedido em questao foi rejeitado!')
							Else
								// ---------------------------------------------------------
								// Envia WorkFlow para aprovacao do proximo Nivel
								// ---------------------------------------------------------
								SC7->( DbSetOrder(1) )
								SC7->( DbSeek(xFilial("SC7")+cNumPC))
								U_WFPCSend(cNumPC)
	
								// ---------------------------------------------------------
								// Tratamento da rastreabilidade do workflow
								// 2o. passo: Processamento do retorno do workflow
								// ---------------------------------------------------------
								//RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '10002')  
	
							EndIf
						EndIf
					EndIf
				End Transaction
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoFinLan("000055")
		EndIf
	EndIf
	
	
	RestArea(aArea)
	RestArea(aAreaSC7)
	RestArea(aAreaSCR)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ ValidPcoLan                                                º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Valida o lancamento no PCO.                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ValidPcoLan()
	Local lRet	   := .T.
	Local aArea    := GetArea()
	Local aAreaSC7 := SC7->(GetArea())
	
	DbSelectArea("SC7") 
	DbSetOrder(1)
	DbSeek(xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM)))
	
	If lRet	:=	PcoVldLan('000055','02','MATA097')
		While lRet .And. !Eof() .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))
			lRet	:=	PcoVldLan("000055","01","MATA097")    
			dbSelectArea("SC7") 
			dbSkip()
		EndDo
	Endif
	
	If !lRet
		PcoFreeBlq("000055")
	Endif
	
	RestArea(aAreaSC7)
	RestArea(aArea)
Return lRet


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³FUNCAO    ³ChkTimeOut³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Funcao responsavel pelo tratamento do time-out do processa_ ³±±
±±³          ³mento do processo de workflow                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function PCTimeOut(oProcess)
	ConOut('TimeOut executado')
Return .T.