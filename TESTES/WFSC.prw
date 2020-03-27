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
User Function WFSC()

	Local nOpc      := 3
	Local cNumPC    := SC1->C1_NUM
	Local lOk       := .T.
	Local aNivel    := {"00","01"}
    Local nNivel    := 0

//======================================================================================================================
// Inicio -  rotina (MATA094)
    For nNivel := 1 to Len(aNivel)
		If aNivel[nNivel] == "00"
			cUser 	:= "000000"
			cAprov 	:= "000001"
			cStatus := "02"
		Else
			cUser 	:= "000002"
			cAprov 	:= "000002"
			cStatus := "01"
		EndIf
			cGrupo 	:= "000002"
			dEmissao:= DATE()
			cTotal 	:= SC1->C1_TOTAL
		U_Exec094(cNumPC,"SC",cUser,cAprov,cGrupo,aNivel[nNivel],cStatus,dEmissao,cTotal)
    Next nNivel
// Fim - (MATA094)
//======================================================================================================================
   		
	If nOpc == 3 .And. lOk 
		MsgRun('Montando processo de Workflow...', 'Aguarde...', {|| U_WFSCSend(cNumPC)})
	EndIf

	//U_WFSCSend(SC1->C1_NUM)
	
Return()	


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³FUNCAO    ³WFSCSend  ³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Funcao responsavel pelo montagem e envio do processo de     ³±±
±±³          ³workflow                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function WFSCSend(cNumPC)
	Local oProcess  := NIL
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
	Local aAreaSC1  := SC1->(GetArea())
	
	
	SC1->(DbSetOrder(1))
	If SC1->(DbSeek(xFilial('SC1')+cNumPC))
		// ----------------------------------------
		// Verifica o controle de alcadas, somente
		// para Pedidos de Compra:
		// ---------------------------------------
		cAliasQry := GetNextAlias()
		BeginSQl Alias cAliasQry
			SELECT 	SCR.CR_STATUS, SCR.R_E_C_N_O_ nRecSCR
			FROM 	%Table:SCR% SCR
			WHERE 	SCR.CR_FILIAL =  %xFilial:SCR% AND
					SCR.CR_NUM    =  %Exp:SC1->C1_NUM% AND
					SCR.CR_TIPO   =  %Exp:'SC'% AND
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
				oProcess := TWFProcess():New('APR_SC', 'Criacao do Processo - Aprovacao de Solicitações')
	
				// ---------------------------------------------------------
				// Criacao de uma tarefa de workflow. Podem 
				// existir varias tarefas. Para cada tarefa, 
				// deve-se informar um nome e o HTML envolvido
				// ---------------------------------------------------------
				oProcess:NewTask('WFA030', '\WORKFLOW\PROCESSOS_COMPRAS\WFA030.HTML')
	
				// ---------------------------------------------------------
				// Determinacao da funcao que realiza o processamento
				// do retorno do workflow
				// ---------------------------------------------------------
				oProcess:bReturn := 'U_WFSCRet()'
	
				// ---------------------------------------------------------
				// Tratamento do timeout. Este tratamento tem o objetivo
				// de determinar o tempo maximo para processamento do retorno
				// ---------------------------------------------------------
				oProcess:bTimeOut := {{'U_SCTimeOut()', 0, 0, 5 }}
	
				// ---------------------------------------------------------
				// Realiza o preenchimento do HTML:
				// ---------------------------------------------------------
				SC1->(DbSetOrder(1))
				SC1->(DbSeek(xFilial('SC1')+cNumPC))
	
				oProcess:oHtml:ValByName('cNumPed'		, SC1->C1_NUM)
				oProcess:oHtml:ValByName('dEmissao'		, SC1->C1_EMISSAO)
				oProcess:oHtml:ValByName('cCodAprov'	, SCR->CR_USER)
		
				While !SC1->(Eof()) .And.; 
						SC1->(C1_FILIAL+C1_NUM) == xFilial('SC1')+cNumPC
	
					AAdd(oProcess:oHtml:ValByName('PED.cItem')		, SC1->C1_ITEM)
					AAdd(oProcess:oHtml:ValByName('PED.cCodPro')	, SC1->C1_PRODUTO)
					AAdd(oProcess:oHtml:ValByName('PED.cDesPro')	, SC1->C1_DESCRI)
					AAdd(oProcess:oHtml:ValByName('PED.cUnidMed')	, SC1->C1_UM)
					AAdd(oProcess:oHtml:ValByName('PED.nQtde')		, Transform(SC1->C1_QUANT, PesqPict('SC1', 'C1_QUANT')))
					AAdd(oProcess:oHtml:ValByName('PED.dDtEntr')	, SC1->C1_DATPRF)
			
					SC1->(DbSkip())
				End
		
				// ---------------------------------------------------------
				// Realiza a gravacao do processo de workflow.
				// Este processo sera gravado no servidor para
				// que seja acessado posteriormente via link 
				// enviado no e-mail de notificacao do processo
				// ---------------------------------------------------------
				cPastaHTM    := 'PROCESSOS_COMPRAS'
				oProcess:cTo := cPastaHTM
	
				// ---------------------------------------------------------
				// Tratamento da rastreabilidade do workflow
				// 1o. passo: Envio do e-mail:
				// ---------------------------------------------------------
				//RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode,'10001')  
	
				// ---------------------------------------------------------
				// Reposiciona o SC1 para gravacao do processo de 
				// workflow no pedido de compras:
				// ---------------------------------------------------------
				SC1->(DbSeek(xFilial('SC1')+cNumPC))
				While !SC1->(Eof()) .And.; 
						SC1->(C1_FILIAL+C1_NUM) == xFilial('SC1')+cNumPC
		
					RecLock('SC1', .F.)
					SC1->C1_WFID := oProcess:fProcessID
					SC1->(MsUnLock())
	
					SC1->(DbSkip())
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
				oProcess:NewTask('WFA040', '\WORKFLOW\PROCESSOS_COMPRAS\WFLinkSC.HTML')
	
				// ---------------------------------------------------------
				// Atualiza os dados no HTML referente 
				// a mensagem com o link:
				// ---------------------------------------------------------
				cHTTPSrv := 'localhost:91/'
				cUrl     := 'http://' + cHttpSrv + 'wf/workflow/messenger/emp' + cEmpAnt + '/' + cPastaHTM + '/' + cMailId + '.htm'
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
				
				oProcess:cSubject := 'Aprovacao de Solicitação de Compra'
					
				// ---------------------------------------------------------
				// Envia o e-mail com link para aprovacao
				// ---------------------------------------------------------
				oProcess:Start()
	
				// ---------------------------------------------------------
				// Libera Objeto
				// ---------------------------------------------------------
				oProcess:Free()
				oProcess:= NIL
			EndIf
		Next nCount
	Endif  
	
	RestArea(aArea)
	RestArea(aAreaSA2)
	RestArea(aAreaSB1)
	RestArea(aAreaSC1)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³FUNCAO    ³WFSCRet   ³Autor  ³Rodrigo dos Santos / Ellen Santiago      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³Funcao responsavel pelo tratamento do retorno do processo de³±±
±±³          ³workflow                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function WFSCRet(oProcess)
	Local cNumPC    := ''
	Local cNumSCR   := ''
	Local cCodAprov := ''
	Local lAprovado := .F.
	Local lContinua := .T.
	Local aRetSaldo := {}
	Local nTotal    := 0
	Local lLiberou  := .F.
	Local cEmailUsu := AllTrim(UsrRetMail(__CUSERID))
	Local cSubject 	:= 'Aprovacao de Solicitação de Compra'
	Local aMensIncon := {}
	
	Local aArea     := GetArea()
	Local aAreaSC1  := {}
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
	If SCR->(DbSeek(xFilial('SCR') + 'SC' + cNumSCR + cCodAprov))
	
		// -----------------------------------------------
		// Posiciona nas tabelas auxiliares
		// -----------------------------------------------
		SAK->( DbSetOrder(1) )
		SAK->( DbSeek(xFilial("SAK")+cCodAprov))
	
		SC1->( DbSetOrder(1) )
		If SC1->( DbSeek(xFilial("SC1")+cNumPC))
			cObsApr := SC1->C1_OBSAPR
			cObsApr += Chr(10)+Chr(13)
			cObsApr += '[OBSERVACOES REALIZADAS PELO APROVADOR: ' + UsrRetName(SCR->CR_USER) + ']' + Chr(10)+Chr(13)
			cObsApr += cObserv
	
			aAreaSC1 := SC1->(GetArea())
			While !SC1->(Eof()) .And.; 
					SC1->(C1_FILIAL+C1_NUM) == xFilial("SC1")+cNumPC
	
				RecLock('SC1', .F.)
				SC1->C1_OBSAPR := /*cObsApr*/'[OBSERVACOES REALIZADAS PELO APROVADOR: ' + UsrRetName(SCR->CR_USER) + ']' + Alltrim(cObserv) + Chr(10)+Chr(13)
				SC1->(MsUnLock())
				SC1->(DbSkip())
	
			End
			RestArea(aAreaSC1)
		EndIf	
	
		SAL->( DbSetOrder(3) )
		SAL->( DbSeek(xFilial("SAL")+SC1->C1_APROV+SAK->AK_COD) )
	
		// -----------------------------------------------
		// Avalia o Status do Documento a ser liberado
		// -----------------------------------------------
		If lContinua .And. !Empty(SCR->CR_DATALIB) .And. SCR->CR_STATUS$'03|05'
			Conout('Esta solicitacao ja foi liberada anteriormente. Somente as solicitacoes que estao aguardando liberacao poderao ser liberadas.')
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
					Conout('Saldo na data insuficiente para efetuar a liberacao da solicitação de compra. Verifique o saldo disponivel para aprovacao na data e o valor total da solicitação.')
					lContinua := .F.
				EndIf
			EndIf
		
			If lContinua
				Begin Transaction
					// ---------------------------------------------------------
					// Executa a liberacao ou rejeicao
					// do Pedido de Compra.
					// ---------------------------------------------------------
					lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SC1->C1_APROV,,,,,cObserv},dDataBase,If(lAprovado,4,6))
		
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
	
							While SC1->(!Eof()) .And.; 
									SC1->C1_FILIAL+SC1->C1_NUM == xFilial("SC1")+PadR(SCR->CR_NUM,Len(SC1->C1_NUM))
	
								Reclock("SC1",.F.)
								SC1->C1_CONAPRO := "L" //-- Atualiza o status (Liberado) no Pedido de Compra
								SC1->(MsUnlock())
	
								// ---------------------------------------------------------
								// Grava os lancamentos nas contas orcamentarias SIGAPCO
								// ---------------------------------------------------------
								PcoDetLan("000055","01","MATA097")
								SC1->( dbSkip() )
							End
	
							SC1->(DbSetOrder(1))
							SC1->(DbSeek(xFilial("SC1")+cNumPC))
							
							//--Monta mensagem para notificação
							aAdd(aMensIncon,'Status da liberação de solicitação de compra:')
    						aAdd(aMensIncon,'')
      						aAdd(aMensIncon,'Aprovado.')
							aAdd(aMensIncon,'')
							aAdd(aMensIncon,'Solicitação Nº: '+cNumPC+'.')


							Notifica(cEmailUsu, cSubject, aMensIncon )
	
						Else
							If SCR->CR_STATUS == '04'	//-- Se Rejeitado
								Conout('O pedido em questao foi rejeitado!')
								
								//--Monta mensagem para notificação
								aAdd(aMensIncon,'Status da liberação de solicitação de compra:')
								aAdd(aMensIncon,'')
								aAdd(aMensIncon,'Rejeitado.')
								aAdd(aMensIncon,'')
								aAdd(aMensIncon,'Solicitação Nº: '+cNumPC+'.')


							Notifica(cEmailUsu, cSubject, aMensIncon )

							Else
								// ---------------------------------------------------------
								// Envia WorkFlow para aprovacao do proximo Nivel
								// ---------------------------------------------------------
								SC1->( DbSetOrder(1) )
								SC1->( DbSeek(xFilial("SC1")+cNumPC))
								U_WFSCSend(cNumPC)
	
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
	RestArea(aAreaSC1)
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
	Local aAreaSC1 := SC1->(GetArea())
	
	DbSelectArea("SC1") 
	DbSetOrder(1)
	DbSeek(xFilial("SC1")+Substr(SCR->CR_NUM,1,len(SC1->C1_NUM)))
	
	If lRet	:=	PcoVldLan('000055','02','MATA097')
		While lRet .And. !Eof() .And. SC1->C1_FILIAL+Substr(SC1->C1_NUM,1,len(SC1->C1_NUM)) == xFilial("SC1")+Substr(SCR->CR_NUM,1,len(SC1->C1_NUM))
			lRet	:=	PcoVldLan("000055","01","MATA097")    
			dbSelectArea("SC1") 
			dbSkip()
		EndDo
	Endif
	
	If !lRet
		PcoFreeBlq("000055")
	Endif
	
	RestArea(aAreaSC1)
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
User Function SCTimeOut(oProcess)
	ConOut('TimeOut executado')
Return .T.


/*/{Protheus.doc} Notifica
	Notificação por e-mail
	@type  Static Function
	@author Igor Silva
	@since 27/03/2020
	@version version
	@param pcTo, cTitle, aMsg, aFiles, lMens
	@return
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function Notifica(cTo, cTitle, aMsg, aFiles, lMens )
	
	Local cBody, nInd
  
	cBody := '<html>'
	cBody += '<div><span class=610203920-12022004><font face=Verdana color=#ff0000 '
	cBody += 'size=2><STRONG>Workflow - Serviço Envio de Mensagens</STRONG></font></span></div><hr>'
	
	For nInd := 1 TO Len(aMsg)
		cBody += '<div><font face=Verdana color=#000080 size=3><span class=216593018-10022004>' + aMsg[nInd] + '</SPAN></FONT></DIV><p>'
	Next

	cBody += '</html>'

	If "@" $ cTo
		WFNotifyAdmin( cTo , cTitle, cBody, aFiles )
	Else
		conout("Não foi enviado e-mail para "+cTo+" referente "+cTitle )
	Endif 
    
Return Nil