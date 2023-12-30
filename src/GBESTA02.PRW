#INCLUDE "TOTVS.CH"

//Legendas
Static oBmpVerde    := LoadBitmap( GetResources(), "BR_VERDE")
Static oBmpVermelho := LoadBitmap( GetResources(), "BR_VERMELHO")
Static oBmpPreto    := LoadBitmap( GetResources(), "BR_PRETO")
Static oBmpAmarelo  := LoadBitmap( GetResources(), "BR_AMARELO")
Static __aPesq      := { }

/*/ GBESTA02
@type function
@author Washington Miranda Leao - TPR SYSTEM
@since 13/05/2022
/*/
User Function GBESTA02()

Local aParam     := {}
Local nTipo    	 := "1"

aAdd(aParam,{01,"Data de" 		, stod(""),"","","","",60,.F.}) //MV_PAR01
aAdd(aParam,{01,"Data Ate"		, stod(""),"","","","",60,.F.}) //MV_PAR02
aAdd(aParam,{01,"Documento de"  , space(09),"","","","",60,.F.}) //MV_PAR03
aAdd(aParam,{01,"Documento Ate" , space(09),"","","","",60,.F.}) //MV_PAR04
aAdd(aParam,{02,"Status", nTipo ,{  "0=Aguardando Contagem", "1=Contagem Realizada", "2=Inventario Gravado",;
                                    "3=Processado", "4=Todos os Status anteriores"},;
                                    90, ".T.", .F.})

If ParamBox(aParam,'Filtro Inventário', , , , , , , , , .T., .T.)
    GBESTA02()

EndIf

Return

/*/ U_GBESTA02()
@type function
@author Rogério Machado - TPR SYSTEM
@since 17/11/2021
/*/

Static Function GBESTA02()  
//Local oButton1
Local oButton2
Local cAlias     := GetNextAlias()
Local aSize      := MsAdvSize(.T.)
Local cQuery     := ""
//Local aCampos    := FWSX3Util():GetAllFields( "ZZ1" , .F. )
Local aAlter     := {"ZZ1_QUANT"} 
Local oGet1
Local cFilPesq   := cFilAnt
Local cGet1      := space(TamSX3("ZZ1_DESC")[01])
Local cPesq      := "1-Código"
Local aPesq      := {"1=Código","2=Descrição","3=Código de Barras"}
Local aStatus    := { "0=Aguardando Contagem", "1=Contagem Realizada", "2=Inventario Gravado", "3=Processado", "4-Todos" }
Static oDlg

Private aHeadLote := {}
Private aColsLote := {}
Private oMsGet
Private cFontUti   := "Tahoma"
Private oFontAno   := TFont():New(cFontUti,,-15)
Private oFontSub   := TFont():New(cFontUti,,-20)
Private oFontSubN  := TFont():New(cFontUti,,-20,,.T.)
Private oFontBtn   := TFont():New(cFontUti,,-14)
Private oDlgPvt
Private oMsGetSBM
Private aHeadSBM := {}
Private aColsSBM := {}

aObjects := {}

aAdd( aObjects, { 100, 005, .T., .T.} )
aAdd( aObjects, { 100, 095, .T., .T., .T.} )

aInfo  := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 0, 0 }
aPObjs := MsObjSize( aInfo, aObjects, .T. )


DEFINE MSDIALOG oDlg TITLE "" FROM aSize[7], 000 To aSize[6], aSize[5] /*COLORS 0, 16777215*/ PIXEL
	

	//Labels gerais        
    @ 004, 187 SAY "GESTAO DE INVENTARIO"  SIZE 200, 030 FONT oFontSub  OF oDlgPvt COLORS RGB(031,073,125) PIXEL
	@ 004, 363 SAY "Pesquisar" SIZE 200, 030 FONT oFontAno  OF oDlgPvt COLORS RGB(031,073,125) PIXEL
	
	@ 003, 010 BUTTON oButton2 PROMPT "Fechar"    	SIZE 037, 012 OF oDlg  ACTION oDlg:End() PIXEL
	@ 003, 050 BUTTON oButton2 PROMPT "Gravar"   	SIZE 037, 012 OF oDlg  ACTION MsAguarde({|| GRAVAB7(oMsGet) }, "Gravando inventário Na Tabela Padrao SB7 ...","Aguarde",.T.)  PIXEL
	@ 003, 090 BUTTON oButton2 PROMPT "Processar"   SIZE 040, 012 OF oDlg  ACTION MsAguarde({|| FILESTA01(oMsGet) }, "Gerando requisições no Estoque ...","Aguarde",.T.)  PIXEL
	@ 003, 135 BUTTON oButton2 PROMPT "Legendas"    SIZE 040, 012 OF oDlg  ACTION InveLegenda() PIXEL
	

    @ 003, aSize[3]-280 ComboBox oPesq Var cPesq Items aPesq Size 71, 10 Of oDlg Pixel
	@ 003, aSize[3]-200 MSGET  oFilial VAR cFilPesq		PICT "@S4"  SIZE 38, 010 OF oDlg COLORS 0, 16777215 PIXEL VALID PesqACols(oMsGet,cGet1,oPesq:nAt,cFilPesq) F3 "SB1"
	@ 003, aSize[3]-160 MSGET  oGet1 VAR cGet1 		    PICT "@S15" SIZE 118, 010 OF oDlg COLORS 0, 16777215 PIXEL VALID PesqACols(oMsGet,cGet1,oPesq:nAt,cFilPesq) F3 "SB1"
	@ 003, aSize[3]-39  BUTTON oButton2 PROMPT "OK"        SIZE 037, 012 OF oDlg  ACTION PesqACols(oMsGet, cGet1, oPesq:nAt,cFilPesq)   PIXEL

	// MONTA CABECALHO DO GRID:
//	aHeader()
	__aPesq := {}
    aAdd(aHeadLote, {""				,       "XX_COR"	,    "@BMP",                        002,                      0,                        ".F.",              "   ", "C", "",    "V",     "",      "",        "", "V"})

    aAdd(aHeadLote, {"Código"		,       "ZZ1_COD"	,  ""							,                            TamSX3("ZZ1_COD")[01],   0,                        ".T.",              ".T.", "C", "",    ""} )
    Aadd(__aPesq, Len(aHeadLote))  // Posição do Código

    aAdd(aHeadLote, {"Descrição" 	,       "ZZ1_DESC"	,   "",                            TamSX3("ZZ1_DESC")[01],    0,                        "NaoVazio()",       ".T.", "C", "",    ""} )
    Aadd(__aPesq, Len(aHeadLote))    // Posição do Descrição

    aAdd(aHeadLote, {"Tipo"			,       "ZZ1_TIPO"	,	 "",                            TamSX3("ZZ1_TIPO")[01],  0,                        "PERTENCE('01234')", ".T.", "C", "",    ""} )
    aAdd(aHeadLote, {"Local"		,       "ZZ1_LOCAL"	, "",                            TamSX3("ZZ1_LOCAL")[01],  0,                        "Pertence('01')",   ".T.", "C", "",    ""} )
	aAdd(aHeadLote, {"Quantidade" 	,       "ZZ1_QUANT"	,  "@E 	999999999.999999"			, TamSX3("ZZ1_QUANT")[01],    6, ".T.","U_GRVQTD()", "N", "", "",""} )

    aAdd(aHeadLote, {"Codigo Barras",       "ZZ1_CODBAR", "",                            TamSX3("ZZ1_CODBAR")[01],  0,                        ".T.", ".T.", "C", "",    ""} )
    Aadd(__aPesq, Len(aHeadLote))    // Posição do Código de Barras

    aAdd(aHeadLote, {"Data"			,       "ZZ1_DATA"	, "",                            TamSX3("ZZ1_DATA")[01],  0,                        ".T.",   ".T.", "C", "",    ""} )
    aAdd(aHeadLote, {"Grupo"		, 		"ZZ1_GRUPO" ,  "",  TamSX3("ZZ1_GRUPO")[01],                      0,                        ".T.",              ".T.", "C", "",    ""} )	
	aAdd(aHeadLote, {"Documento"	, 		"ZZ1_DOC" 	,  ""							,  TamSX3("ZZ1_DOC")[01],                      0,                        ".T.",              ".T.", "C", "",    ""} )	
	AAdd(aHeadLote, {"Status"  		, 		"ZZ1_STATUS", PesqPict("ZZ1", "ZZ1_STATUS")  , TamSX3("ZZ1_STATUS")[01]  , 0, "Pertence('01234')", ".T.", "C", "","0=Aguardando Contagem;1=Contagem Realizada;2=Inventario Gravado;3=Processado;4=Todos" } )
    AAdd(aHeadLote, {"Recno"     	, 		"XX_RECNO"  , ""                             , 6                          , 0, ".F.", ".F.", "N", "", } )
    aAdd(aHeadLote, {"Filial"		,       "ZZ1_FILIAL"	,  ""							,                            TamSX3("ZZ1_FILIAL")[01],   0,                        ".T.",              ".T.", "C", "",    ""} )
    Aadd(__aPesq, Len(aHeadLote))    // Posição do Código de Barras
    aAdd(aHeadLote, {"Contagem"		,       "ZZ1_CONTAG",  ""							,                            TamSX3("ZZ1_CONTAG")[01],   0,                        ".T.",              ".T.", "C", "",    ""} )

	//Query com os campos para  montar o Acols, quando for necessário adicionar campos no acols, será necessário incluir na query, aHeader
	cQuery := "SELECT ZZ1.R_E_C_N_O_ AS RECNO,ZZ1_FILIAL,ZZ1_COD,ZZ1_DESC,ZZ1_TIPO,ZZ1_LOCAL, "
    cQuery +=        "ZZ1_QUANT,ZZ1_DOC,ZZ1_GRUPO,ZZ1_CODBAR,ZZ1_DATA,ZZ1_STATUS,ZZ1_CONTAG "
    cQuery +=  " FROM " + RetSQLName("ZZ1") + " ZZ1 "
	cQuery += " WHERE ZZ1.D_E_L_E_T_ = '' "
	cQuery +=    "AND ZZ1_DATA  BETWEEN '" +DTOS(MV_PAR01)+ "' AND '" + DTOS(MV_PAR02)+ "' "
    cQuery +=    "AND ZZ1_DOC  BETWEEN '" +MV_PAR03+ "' AND '" + MV_PAR04+ "' "
	
	If Left(MV_PAR05,1) <> "4"
		cQuery += " AND ZZ1_STATUS = '" + left(mv_par05, 1) + "'" 
    EndIf
	// 0=Aguardando Contagem;1=Contagem Realizada;2=Inventario Gravado;3=Processado

	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .T., .T.)
    IF (cAlias)->(Eof())
        Alert("Não foram localizados produtos com o status: " + aStatus[val(mv_par05) + 1] )
        (cAlias)->(DbCloseArea())
        Return .f.
    Endif

    //Definindo a legenda padrão como preto
    oBmpAux := oBmpPreto
	
	// ITENS DO GRID
	While !(cAlias)->(Eof())
		
		 
		IF (cAlias)->ZZ1_STATUS = "0" 
			oBmpAux := oBmpPreto	//Aguardando Contagem 
		EndIF
		
		IF (cAlias)->ZZ1_STATUS = "1" 
			oBmpAux := oBmpAmarelo //Contagem Realizada
		EndIF

          
		IF (cAlias)->ZZ1_STATUS = "2" 
			oBmpAux := oBmpVerde //Inventário Gravado
		EndIF
		
		IF (cAlias)->ZZ1_STATUS = "3" 
			oBmpAux := oBmpVermelho //Inventário Processado.
		EndIF
           

		aAdd(aColsLote, {oBmpAux,; // "ZZ1_COD"
                         (cAlias)->ZZ1_COD,; // "ZZ1_COD"
						 ALLTRIM((cAlias)->ZZ1_DESC),;// "ZZ1_DESC"
						 (cAlias)->ZZ1_TIPO,; //"ZZ1_TIPO"						 
						 (cAlias)->ZZ1_LOCAL,; //"ZZ1_LOCAL"
						 (cAlias)->ZZ1_QUANT,; //"ZZ1_QUANT"						 						 						 
						 (cAlias)->ZZ1_CODBAR,; //"ZZ1_CODBAR"
						 STOD((cAlias)->ZZ1_DATA),; //"ZZ1_DATA"						 
						 (cAlias)->ZZ1_GRUPO,; //"ZZ1_GRUPO"						 
						 (cAlias)->ZZ1_DOC,; //"ZZ1_DOC"						 
						 (cAlias)->ZZ1_STATUS,; //"ZZ1_STATUS"
						 (cAlias)->RECNO,;
					 	 (cAlias)->ZZ1_FILIAL,; // "ZZ1_FILIAL"
					 	 (cAlias)->ZZ1_CONTAG,; // "ZZ1_CONTAG"
                         .F.})
		(cAlias)->(dbSkip())
	EndDo

    // Caso realizar alteração na estrutura campos ajustar também nesse ponto (ver Aadd em aColsLote acima)
   // senão for encontrado nenhum registro com o estatus procurado, o sistema alimenta o Array com dados vazios,
   // para não dar error. 
    If Len(aColsLote) == 0
		aAdd(aColsLote, {oBmpAmarelo,; // "ZZ1_COD"
                         "",; // "ZZ1_COD"
						 "",;// "ZZ1_DESC"
						 "",; //"ZZ1_TIPO"						 
						 "",; //"ZZ1_LOCAL"
						 0,; //"ZZ1_QUANT"						 						 						 
						 "",; //"ZZ1_CODBAR"
						 Ctod(""),; //"ZZ1_DATA"						 
						 "",; //"ZZ1_GRUPO"						 
						 "",; //"ZZ1_DOC"						 
						 "",; //"ZZ1_STATUS"
						 0,;    // Recno
					 	 "",; // "ZZ1_FILIAL"
					 	 "",; // "ZZ1_CONTAG"
                        .F.})   // Deletado
    EndIF
    // nStyle	
    // nOpc. Pode ser utilizada GD_INSERT + GD_UPDATE + GD_DELETE para criar a flexibilidade da MsNewGetdados.
	oMsGet    := MsNewGetDados():New(  aSize[1]+20 ,aSize[1]+2 , aSize[4]-40, aSize[3] ,GD_DELETE /* nOpc */,'AllwaysTrue' ,'AllwaysTrue', ""      , aAlter, 000    , 999  ,'AllwaysTrue', ""           , "AllwaysFalse" , oDlg   , aHeadLote  , aColsLote)
  
  ACTIVATE MSDIALOG oDlg CENTERED

Return


/*/
FILESTA01
@type function
@author Rogério Machado - TPR SYSTEM
@since 17/11/2021
/*/

Static Function GRAVAB7(oMsGet)

Local nX       	:= 1

Local oExcel     := FWMsExcel():New()

Local cTitSheet  := "Itens Zerados"
Local cTitTable	 := "Pre Inventario"
Local cFile      := GetTempPath()
Local cXMLFile   := "Itens_zerados"  + StrTran(Time(),":","") + ".xls"

Local lQtdZer	 := .F.


	//Monta Planilha com os itens zerados 
	oExcel:SetTitleFrColor("#FFFFFF")
    oExcel:SetTitleBgColor("#000666")
       
    oExcel:AddworkSheet(cTitSheet)
    oExcel:AddTable (cTitSheet,cTitTable)
        
    oExcel:AddColumn(cTitSheet,cTitTable,"Produto"	                 	 ,1,1)  //1
    oExcel:AddColumn(cTitSheet,cTitTable,"Descrição"	                 ,1,1)  //2
    oExcel:AddColumn(cTitSheet,cTitTable,"Quantidade"	                 ,1,1)  //3
	oExcel:AddColumn(cTitSheet,cTitTable,"Documento"	                 ,1,1)  //3

For nX := 1 To Len(oMsGet:aCols)
	If oMsGet:aCols[nX][6] == 0 .And. oMsGet:aCols[nX][11] = "0"
		oExcel:AddRow(cTitSheet,cTitTable,{;
                    oMsGet:aCols[nX][2]                                                       ,;	//1
                    oMsGet:aCols[nX][3]                                                        ,;	//2                    
					oMsGet:aCols[nX][6]                                                        ,;	//2                    
                    oMsGet:aCols[nX][10]                                                        })										
		lQtdZer	 := .T.	
	EndIf	
Next

//Valida se tem quantidade zero,  apresenta msg pra o usuário 
	IF lQtdZer
		If MsgNoYes("Existem Itens com a quantidade zero que ainda não foram contados!!"+CHR(13) + CHR(10) +CHR(13) + CHR(10)+ " Deseja exportar uma lista em Excel?" ,"Atençãos")
			
			oExcel:Activate()
			oExcel:GetXMLFile(cXMLFile)
			
			CpyS2T("\system\" + cXMLFile, cFile, .T.)
			
			If !ApOleClient('MsExcel')
				MsgAlert("MsExcel nao instalado")
				Return
			EndIf

			oExcelApp := MsExcel():New()
			oExcelApp:WorkBooks:Open(cFile + cXMLFile) //Abre uma planilha
			oExcelApp:SetVisible(.T.)
		else
			IF MsgNoYes("Deseja alterar o Status dos itens com as quantidades zeradas para 'Contagem Realizada'? " ,"Atenção")
				For nX := 1 To Len(oMsGet:aCols)
					If oMsGet:aCols[nX][6] == 0 .And. oMsGet:aCols[nX][11] = "0"
						oMsGet:aCols[nX][11] := "1"
						//Posiciona Na tabela ZZ1 no recno correspondente 
						DbSelectArea("ZZ1")
						DbSetOrder(1)
						ZZ1->(DBGOTO(oMsGet:aCols[nX][12]))
						RecLock("ZZ1", .F.)
							ZZ1->ZZ1_STATUS := "1"						
						MsUnlock()
					EndIf

				Next
				lQtdZer	:= .F. //Coloca Falso para entrar na gravação da SB7
			EndIF
		EndIF

	EndIF

	If !lQtdZer
		If MsgNoYes("Serão gravados todos os itens no inventário, independente da quantidade informada!!!"+CHR(13) + CHR(10)+ CHR(13)+ CHR(10)+" Confirma a gravação?" ,"Atenção")
				For nX := 1 To Len(oMsGet:aCols)					
					IF oMsGet:aCols[nX][11] == "2"//Altera Status para Aguardando Processamento
						oMsGet:aCols[nX][1] := oBmpVerde //Inventário Gravado.
					EndIF
					If oMsGet:aCols[nX][11] == "1" //Valida se é o status de contagem Realizada
						
						oMsGet:aCols[nX][11] := "2"// Altera Status para Aguardando Processamento
						oMsGet:aCols[nX][1] := oBmpVerde //Inventário Processado.
						
                        Begin Transaction
                        DbSelectArea("ZZ1")
						DbSetOrder(1)
						ZZ1->(DBGOTO(oMsGet:aCols[nX][12]))				

						DbSelectArea("SB7")	
						SB7->(DbSetOrder(3))//B7_FILIAL+B7_DOC+B7_COD+B7_LOCAL
						IF 	!SB7->(DBSeek(xFilial("SB7")+ZZ1->ZZ1_DOC+ZZ1->ZZ1_COD+ZZ1->ZZ1_LOCAL))
							RecLock("SB7",.T.)
								SB7->B7_FILIAL		:= ZZ1->ZZ1_FILIAL					
								SB7->B7_COD			:= ZZ1->ZZ1_COD				
								SB7->B7_LOCAL		:= ZZ1->ZZ1_LOCAL			
								SB7->B7_TIPO		:= ZZ1->ZZ1_TIPO			
								SB7->B7_DOC			:= ZZ1->ZZ1_DOC				
								SB7->B7_QUANT		:= ZZ1->ZZ1_QUANT			
								SB7->B7_CONTAGE  	:= ZZ1->ZZ1_CONTAG
								SB7->B7_DATA		:= MsDate()					
								SB7->B7_STATUS		:= "1"
							SB7->(MsUnLock())						
						EndIF

        				RecLock('ZZ1',.F.)			
							ZZ1->ZZ1_STATUS  := "2"			
						ZZ1->( MsUnLock() )	
							//POSICIONA NA SB7
                        End Transaction
						
					Endif	
				Next
		EndIF
	EndIF

	
oMsGet:Refresh(.T.)
oMsGet:ForceRefresh()
oMsGet:GoTo(1)

Return
/*/
Função para pesquisa no aCols
@type function
@author Rogério Machado - TPR SYSTEM
@since 17/11/2021
/*/
Static Function PesqACols(oMsGet,cGet1,nPesq,cFilPesq)

Local nPosicao := 0
Local nX       := 1
local nRecno   := 0
Local nPos     := If(nPesq == 0, 1, nPesq)
Local nPosPesq := __aPesq[nPos]
Local nPosFil  := __aPesq[Len(__aPesq)]
Local nTamGet  := Len(AllTrim(cGet1))

If Empty(cFilPesq) .Or. Empty(cGet1)
    Return .T.
EndIf

// Esse bloco realiza a pesquisa
For nX := 1 To Len(oMsGet:aCols)
    If  AllTrim(oMsGet:aCols[nX][nPosFil]) == AllTrim(cFilPesq) .And.;
        Left(AllTrim(cGet1), nTamGet) == Left(oMsGet:aCols[nX][nPosPesq], nTamGet)
		nPosicao := nX
		nRecno := oMsGet:aCols[nX][12]
		Exit
	EndIf
Next

If nPosicao == 0
	MsgInfo("Produto não encontrado !","ATENÇÃO")
    Return .T.
EndIf

oMsGet:GoTo(nPosicao)
//Chamar a função apenas se for consultado algum código.
If !Empty(cGet1) 
    // { "0=Aguardando Contagem", "1=Contagem Realizada", "2=Inventario Gravado", "3=Processado", "4-Todos" }
	If oMsGet:aCols[nPosicao][11] < "2" 
		GRVZZ1(nPosicao,oMsGet,nRecno)
	else
		MsgInfo('Contagem já foi gravada!! [' + oMsGet:aCols[nPosicao][2] + "]","ATENÇÃO")
	EndIF
EndIF

Return .T.


/*
@ Thiago TPR - 26/11/2021
@ Grava  conteudo a cada campo alterado. 
*/
Static Function GRVZZ1(nPosicao,oMsGet,nRecno)
	
local oDlg1
local oSay 
local oButton

local lOpc := .F.

private oProduto
private oCodBar
private oDescri
private oQtd
private oLocal


private cProduto  	:= CriaVar( "ZZ1_COD"  	  , .F. )
private cCodBar 	:= CriaVar( "ZZ1_CODBAR"  , .F. )
private cDescri 	:= CriaVar( "ZZ1_DESC" 	  , .F. )
private nQtd 		:= CriaVar( "ZZ1_QUANT"   , .F. ) 
private cLocal  	:= CriaVar( "ZZ1_LOCAL"   , .F. ) 

DbSelectArea("ZZ1")
DbSetOrder(1)
ZZ1->(DBGOTO(nRecno))

cProduto := ZZ1->ZZ1_COD
cCodBar	 := ZZ1->ZZ1_CODBAR
cDescri  := Alltrim(ZZ1->ZZ1_DESC)
nQtd	 := ZZ1->ZZ1_QUANT
cLocal   := ZZ1->ZZ1_LOCAL


Define MSDIALOG oDlg1 from 250,180 to 499,739 TITLE "Lançamento de Inventário" of oMainWnd pixel STYLE DS_MODALFRAME	

oDlg1:lMaximized := .F.
oDlg1:lEscClose  := .F.

//Mostra Nome dos campos na Tela "Say"
//------------------------------------
oSay := TSay():New( 005, 010, { || "Produto" 			}, oDlg1,, ,,,, .T.,,,80,10 )
oSay := TSay():New( 005, 070, { || "Descrição" 			}, oDlg1,, ,,,, .T.,,,80,10 )
oSay := TSay():New( 035, 010, { || "Código de Barras" 	}, oDlg1,, ,,,, .T.,,,80,10 )
oSay := TSay():New( 035, 210, { || "Local  " 			}, oDlg1,, ,,,, .T.,,,80,10 )
oSay := TSay():New( 065, 110, { || "Quantidade  " 		}, oDlg1,, ,,,, .T.,,,80,10 )


//Habilita Get
//------------
oProduto  	:= TGet():New(015,010,{ |u| If( PCount() > 0, cProduto   := u, cProduto ) },oDlg1,050,010,PesqPict("ZZ1","ZZ1_COD") ,{||},,,,,,.T.,,,{|| .F.},,,,,,	,"cProduto"  )
oDescri  	:= TGet():New(015,070,{ |u| If( PCount() > 0, cDescri  	 := u, cDescri  ) },oDlg1,190,010,                            ,               ,,,,,,.T.,,,{|| .F.},,,,,,     ,"cDescri" )
oCodBar		:= TGet():New(045,010,{ |u| If( PCount() > 0, cCodBar	 := u, cCodBar 	) },oDlg1,190,010,PesqPict("ZZ1","ZZ1_CODBAR"),               ,,,,,,.T.,,,{|| .F.},,,,,,     ,"cCodBar" )
oLocal 		:= TGet():New(045,210,{ |u| If( PCount() > 0, cLocal 	 := u, cLocal 	) },oDlg1,030,010,PesqPict("ZZ1","ZZ1_LOCAL")  ,               ,,,,,,.T.,,,{|| .F.},,,,,,    ,"cLocal"  )           
oQtd  	 	:= TGet():New(075,110,{ |u| If( PCount() > 0, nQtd 		 := u, nQtd 	) },oDlg1,060,010,PesqPict("ZZ1","ZZ1_QUANT") ,               ,,,,,,.T.,,,{|| .T.},,,,,,     ,"nQuant"  )           


//Boti para fechar a janela
//--------------------------
oButton := TButton():Create( oDlg1,100,090,"Confirmar",{|| lOpc := confir(oDlg1) },36,16,,,,.T.,,,,,,)
oButton := TButton():Create( oDlg1,100,130,"Cancelar" ,{||oDlg1:End()},36,16,,,,.T.,,,,,,)

oDlg1:Activate( ,,,.T.,,, )

if lOpc	
	//grava a quantidade na  tela 
    oMsGet:aCols[nPosicao][6] := nQtd
    M->ZZ1_QUANT := nQtd
    n := nPosicao

    UpdZZ1()
Endif

RETURN

Static Function Confir(oDlg1)
oDlg1:End()
Return .T.

/*
	@Função para gravar a contagem na tabela
*/
User Function GRVQTD()
	
Local nRecno := oMsGet:aCols[n][12]
Local lRet	 := .T.
	
	DbSelectArea("ZZ1")
	//Grava na Tabela 
	ZZ1->(DBGOTO(nRecno))	
	//Validade se a quantidade da contagem ja foi gravada na tabela SB7, caso sim, não será permitida nova conagem. 
	If ! ZZ1->ZZ1_STATUS $ "1#0" 
		MsgInfo("a Contagem do produto: "+ZZ1->ZZ1_COD +"-"+ZZ1->ZZ1_DESC+" já foi gravada."+CHR(13) + CHR(10)+ "A quantidade digitada será ignorada!!!","GBESTA02")
		oMsGet:aCols[n][6]	:= ZZ1->ZZ1_QUANT
		lRet := .F.
	Else
		//Após localizar o Recno pela linha posicionada 
        UpdZZ1()
	EndIF
	//Atualiza a Tela	
	// oMsGet:Refresh(.T.)
	// oMsGet:ForceRefresh()
	// oMsGet:GoTo(n)
	
Return lRet

// Função para atualizar a ZZ1 e o aCols do Grid
Static Function UpdZZ1

	DbSelectArea("ZZ1")
    RecLock('ZZ1',.F.)			
        // { "0=Aguardando Contagem", "1=Contagem Realizada", "2=Inventario Gravado", "3=Processado", "4-Todos" }

    //Atualiza o Status
    ZZ1->ZZ1_STATUS := oMsGet:aCols[n][11]
    IF oMsGet:aCols[n][6] = 0
        oMsGet:aCols[n][1] := oBmpPreto	//Aguardando Contagem 
        ZZ1->ZZ1_STATUS := "0"
    EndIF

    IF oMsGet:aCols[n][6] > 0 .And. ZZ1->ZZ1_STATUS < "2"
        oMsGet:aCols[n][1] := oBmpAmarelo // Contagem Realizada
        ZZ1->ZZ1_STATUS = "1"
    Endif

    IF ZZ1->ZZ1_STATUS == "2"
        oMsGet:aCols[n][1] := oBmpVerde //Aguardando Processar  Inventário
    EndIF

    IF ZZ1->ZZ1_STATUS == "3" 
        oMsGet:aCols[n][1] := oBmpVermelho//Inventário Processado
    EndIF

    ZZ1->ZZ1_QUANT := M->ZZ1_QUANT//oMsGet:aCols[n][6] 			
    oMsGet:aCols[n][11] := ZZ1->ZZ1_STATUS
    ZZ1->( MsUnLock() )	

Return

// Procesamento Inventário
// Método 1

Static Function FILESTA01(oMsGet)

Local lAuto	   	   := .T.
Local cCodInv	   := ""
Local lIndividual  := .F.
Local lOk	   	   := .T.
Local nI 		   := 1

Private lMsErroAuto := .F.

DbSelectArea("ZZ1")
DbSetOrder(1)

For nI := 1 to Len(oMsGet:aCols)


	IF cCodInv <> oMsGet:aCols[nI][10]
		IF oMsGet:aCols[nI][11] == '2' //valida o status de gravado
			DbSelectArea("SB7")
			DbSetOrder(3)
			If !SB7->(MsSeek(xFilial("SB7")+oMsGet:aCols[nI][10]))	
				lOk := .F.	
			    ConOut(OemToAnsi("Cadastrar inventário: "+oMsGet:aCols[nI][10]))
			EndIf
			
            If lOk	
                ConOut(Repl("-",80))	
                ConOut(PadC("Acerto de Inventário",80))	
                ConOut("Inicio: "+Time())		

                //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿	
                //| Processamento                                       |	
                //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   					                

                MSExecAuto({|x,y,z| mata340(x,y,z)}, lAuto, Alltrim(oMsGet:aCols[nI][10]), lIndividual)				

                If !lMsErroAuto			
                    ConOut("Processado com Sucesso! Documento: "+oMsGet:aCols[nI][10])			
                    ZZ1->(DBGOTO(oMsGet:aCols[nI][12]))
                    RecLock('ZZ1',.F.)			
                    ZZ1->ZZ1_STATUS := "3"
                    ZZ1->( MsUnLock() )	

                    oMsGet:aCols[nI][11] := "3"
                Else			
                    ConOut("Erro no processamento de acerto de inventário!")		
                EndIf		
				ConOut("Fim  : "+Time())
			EndIf

			
		EndIF
	EndIF
	cCodInv := oMsGet:aCols[nI][10]
Next nI

Return Nil


//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
 
//Constantes
#Define STR_PULA        Chr(13)+Chr(10)
 
/*/zConsMark
Função para consulta genérica com marcação de dados
@author Thiago TPR
@since 19/02/2015
@version 1.0
    param cAliasM, Caracter, Alias da tabela consultada
    param aCamposM, Array, Campos que serão montados na grid de marcação
    param cFiltroM, Caracter, Filtragem da tela (SQL)
    param nTamanM, Numérico, Tamanho do campo de retorno
    param cCheckM, Caracter, Campo que será checado
    param lEditM, Lógico, Permite editar o retorno
    param cSepM, Caracter, Caracter de separação do texto
    param lAllFilM, Lógico, Identifica se são todas as filiais (inclusive de todas as empresas)
    return lRetorn, retorno se a consulta foi confirmada ou não
    example
    u_zConsMark("SED", {"ED_CODIGO","ED_DESCRIC"}, " AND ED_FILIAL = '"+xFilial("SED")+"' ", 99, "ED_CODIGO", .F., ";")
    u_zConsMark("SB1", {"B1_COD","B1_DESC","B1_TIPO"}, " AND B1_FILIAL = '"+xFilial("SB1")+"' ", 99, "B1_COD", .F., "#")
    u_zConsMark("SZB", {"ZB_CODIGO","ZB_DESCRI"}, " ", 99, "ZB_CODIGO", .F., ";")
    u_zConsMark("SM0", {}, " ", 99, "XX_CODFIL", .F., ";")
    u_zConsMark("SZA", {"ZA_FILCONT","ZA_CONTRAT","ZA_NOMECLI","ZA_DESCPRO"}, " ", 99, "ZA_CONTRAT", .F., ";")
    @obs O retorno da consulta é pública (__cRetorn) para ser usada em consultas específicas
    Para consulta da SM0, não precisa passar colunas, é tratado diretamente no fonte
/*/
                                                                                                                                                           
 
User Function zConsMark(cAliasM, aCamposM, cFiltroM, nTamanM, cCheckM, lEditM, cSepM, lAllFilM)
    Local cFilBkp := cFilAnt
    Local aAreaM0 := SM0->(GetArea())
    Local aArea := GetArea()
    Local nTamBtn := 50
    //Defaults
    Default cAliasM     := ""
    Default aCamposM     := {}
    Default cFiltroM     := ""
    Default nTamanM     := 99
    Default cCheckM     := ""
    Default lEditM         := .F.
    Default cSepM         := ";"
    Default lAllFilM     := .T.
    //Privates
    Private cFiltro     := cFiltroM
    Private cAliasPvt     := cAliasM
    Private aCampos     := aCamposM
    Private nTamanRet     := nTamanM
    Private cCampoRet     := cCheckM
    Private lAllFil     := .T.
    //MsSelect
    Private oMAux
    Private cArqs
    Private cMarca := "OK"
    Private aStrut := {}
    Private aHeadRegs := {}
    Private cAliasTmp:="CHK_"+RetCodUsr()
    //Tamanho da janela
    Private nJanLarg := 0800
    Private nJanAltu := 0500
    //Gets e Dialog
    Private oDlgMark
    Private oGetPesq, cGetPesq := Space(100)
    Private oGetReto, cGetReto := Space(nTamanM)
    //Retorno
    Private lRetorn := .F.
    Public  __cRetorn := Space(nTamanM)
     
    //Se tiver o alias em branco ou não tiver campos
    If Empty(cAliasM) .Or. (Len(aCamposM) <= 0 .And. cAliasM != "SM0") .Or. Empty(cCheckM)
        MsgStop("Alias em branco e/ou Sem campos para marcação!", "Atenção")
        Return lRetorn
    EndIf
     
    //Criando a estrutura para a MsSelect
    fCriaMsSel()
     
    //Criando a janela
    DEFINE MSDIALOG oDlgMark TITLE "Consulta de Dados" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Pesquisar
        @ 003, 003 GROUP oGrpPesqui TO 025, (nJanLarg/2)-3 PROMPT "Pesquisar: "    OF oDlgMark COLOR 0, 16777215 PIXEL
            @ 010, 006 MSGET oGetPesq VAR cGetPesq SIZE (nJanLarg/2)-12, 010 OF oDlgMark COLORS 0, 16777215  VALID (fVldPesq())      PIXEL
         
        //Dados
        @ 028, 003 GROUP oGrpDados TO (nJanAltu/2)-28, (nJanLarg/2)-3 PROMPT "Dados: "    OF oDlgMark COLOR 0, 16777215 PIXEL
            oMAux := MsSelect():New( cAliasTmp, "XX_OK",, aHeadRegs,, cMarca, { 035, 006, (nJanAltu/2)-28-028, (nJanLarg/2)-6 } ,,, )
            oMAux:bAval := { || ( fGetMkA( cMarca ), oMAux:oBrowse:Refresh() ) }
            oMAux:oBrowse:lHasMark := .T.
            oMAux:oBrowse:lCanAllMark := .F.
            @ (nJanAltu/2)-28-025, 006 SAY oSayReto PROMPT "Retorno:"     SIZE 040, 007 OF oDlgMark COLORS RGB(0,0,0) PIXEL
            @ (nJanAltu/2)-28-015, 006 MSGET oGetReto VAR cGetReto SIZE (nJanLarg/2)-12, 010 OF oDlgMark COLORS 0, 16777215      PIXEL
         
            //Populando os dados da MsSelect
            fPopula()
         
        //Ações
        @ (nJanAltu/2)-25, 003 GROUP oGrpAcoes TO (nJanAltu/2)-3, (nJanLarg/2)-3 PROMPT "Ações: "    OF oDlgMark COLOR 0, 16777215 PIXEL
            @ (nJanAltu/2)-19, (nJanLarg/2)-((nTamBtn*1)+06) BUTTON oBtnConf PROMPT "Confirmar" SIZE nTamBtn, 013 OF oDlgMark ACTION(fConfirm())     PIXEL
            @ (nJanAltu/2)-19, (nJanLarg/2)-((nTamBtn*2)+09) BUTTON oBtnLimp PROMPT "Limpar" SIZE nTamBtn, 013 OF oDlgMark ACTION(fLimpar())     PIXEL
            @ (nJanAltu/2)-19, (nJanLarg/2)-((nTamBtn*3)+12) BUTTON oBtnCanc PROMPT "Cancelar" SIZE nTamBtn, 013 OF oDlgMark ACTION(fCancela())     PIXEL
             
        //Se não for editável, desabilita o get de retorno
        If ! lEditM
            oGetReto:lReadOnly := .T.
        EndIf
         
        oMAux:oBrowse:SetFocus()
    //Ativando a janela
    ACTIVATE MSDIALOG oDlgMark CENTERED
     
    cFilAnt := cFilBkp
    RestArea(aArea)
    RestArea(aAreaM0)
Return lRetorn
 
/*---------------------------------------------------------------------*
 | Func:  fCriaMsSel                                                   |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função para criar a estrutura da MsSelect                    |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fCriaMsSel()
    Local aAreaX3 := SX3->(GetArea())
    Local nAtual  := 1

    //Zerando o cabeçalho e a estrutura
    aHeadRegs := {}
    aStrut := {}
     
    //Adicionando coluna de OK
    //                    Campo            Titulo        Mascara
    aAdd( aHeadRegs, {    "XX_OK",    ,    " ",        "" } )
     
    //                Campo        Tipo    Tamanho        Decimal
    aAdd( aStrut, {    "XX_OK",    "C",    002,        000} )
     
    DbSelectArea("SX3")
    SX3->(DbSetOrder(2)) // Campo
    SX3->(DbGoTop())
     
    //Se for consulta de filiais
    If cAliasPvt == "SM0"
        //                        Campo                Titulo            Mascara
        aAdd( aHeadRegs, {    "XX_CODFIL",     ,    "Código",        "@!" } )
        aAdd( aHeadRegs, {    "XX_DESCRI",     ,    "Descrição",    "@!" } )
        aAdd( aHeadRegs, {    "XX_CIDENT",     ,    "Cidade",        "@!" } )
        aAdd( aHeadRegs, {    "XX_ESTENT",     ,    "Estado",        "@!" } )
        aAdd( aHeadRegs, {    "XX_CGC",         ,    "CNPJ",        "@R 99.999.999/9999-99" } )
         
        //                    Campo            Tipo    Tamanho        Decimal    
        aAdd( aStrut, {    "XX_CODFIL",    "C",    Len(cFilAnt),    0} )
        aAdd( aStrut, {    "XX_DESCRI",    "C",    30,                0} )
        aAdd( aStrut, {    "XX_CIDENT",    "C",    30,                0} )
        aAdd( aStrut, {    "XX_ESTENT",    "C",    2,                0} )
        aAdd( aStrut, {    "XX_CGC",        "C",    16,                0} )
     
    Else
        //Percorrendo os campos
        For nAtual := 1 To Len(aCampos)
            cCampoAtu := aCampos[nAtual]
         
            //Se coneguir posicionar no campo
            If SX3->(DbSeek(cCampoAtu))
                //                    Campo            Titulo        Mascara
                aAdd( aHeadRegs, {    cCampoAtu,     ,    X3Titulo(),    PesqPict(cAliasPvt  , cCampoAtu) } )
                 
                //                Campo        Tipo            Tamanho                    Decimal    
                aAdd( aStrut, {    cCampoAtu,    SX3->X3_TIPO,    TamSX3(cCampoAtu)[01],    TamSX3(cCampoAtu)[02]} )
            EndIf
        Next
         
        //                        Campo                Titulo            Mascara
        aAdd( aHeadRegs, {    "XX_RECNUM",     ,    "RecNo",        "" } )
         
        //                    Campo            Tipo    Tamanho        Decimal    
        aAdd( aStrut, {    "XX_RECNUM",    "C",    18,                0} )
         
    EndIf
 
    //Excluindo dados da tabela temporária, se tiver aberta, fecha a tabela
    If Select(cAliasTmp)>0
        (cAliasTmp)->(DbCloseArea())
    EndIf
    fErase(cAliasTmp+".DBF")
     
    //Criando tabela temporária
    cArqs:= CriaTrab( aStrut, .T. )             
    dbUseArea( .T.,"DBFCDX", cArqs, cAliasTmp, .T., .F. )
     
    RestArea(aAreaX3)
Return
 
/*---------------------------------------------------------------------*
 | Func:  fPopula                                                      |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função que popula a tabela auxiliar da MsSelect              |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fPopula()
    Local nAtu := 0
    Local nEmp := 0
    Local nGrp := 0
    Local nAtual := 0

    //Excluindo dados da tabela temporária, se tiver aberta, fecha a tabela
    If Select(cAliasTmp)>0
        (cAliasTmp)->(DbCloseArea())
    EndIf
    fErase(cAliasTmp+".DBF")
     
    //Criando tabela temporária
    cArqs:= CriaTrab( aStrut, .T. )             
    dbUseArea( .T.,"DBFCDX", cArqs, cAliasTmp, .T., .F. )
     
    //Se for consulta de filial
    If cAliasPvt == "SM0"
        aAreaM0 := SM0->(GetArea())
        cFilBk  := cFilAnt
        cEmpBk  := cEmpAnt
        aUnitNeg:= Iif(lAllFil, FWAllGrpCompany(), {SM0->M0_CODIGO})
        aEmpAux := Iif(lAllFil, FWAllCompany(), {cEmpAnt})
     
        //Percorrendo os grupos de empresa
        For nGrp := 1 To Len(aUnitNeg)
            cUnidNeg := aUnitNeg[nGrp]
             
            //Percorrendo as empresas
            For nEmp := 1 To Len(aEmpAux)
                cEmpAnt := aEmpAux[nEmp]
                aFilAux := FWAllFilial(cEmpAnt)
                //Percorrendo as filiais listadas
                For nAtu := 1 To Len(aFilAux)
                    //Se o tamanho da filial for maior, atualiza
                    If Len(cFilAnt) > Len(aFilAux[nAtu])
                        cFilAnt := cEmpAnt + aFilAux[nAtu]
                    Else
                        cFilAnt := aFilAux[nAtu]
                    EndIf 
                     
                    //Posiciono na empresa (para poder pegar o ident)
                    SM0->(DbGoTop())
                    SM0->(DbSeek(cUnidNeg+cFilAnt)) //é utilizado o 01, por grupo de empresas, caso necessário rotina pode ser adaptada
                 
                    //Se tiver pesquisa
                    If !Empty(cGetPesq)
                        //Se não bater a pesquisa, pula o registro
                        If !(     Alltrim(Upper(cGetPesq)) $ Upper(cFilAnt) .Or.;
                                Alltrim(Upper(cGetPesq)) $ Upper(SM0->M0_CIDENT) .Or.;
                                Alltrim(Upper(cGetPesq)) $ Upper(SM0->M0_ESTENT) .Or.;
                                Alltrim(Upper(cGetPesq)) $ Upper(SM0->M0_CGC))
                            Loop
                        EndIf
                    EndIf
                     
                    cOk := Space(Len(cMarca))
                    //Se já existir no retorno, será Ok
                    If Alltrim(cFilAnt) $ cGetReto
                        cOk := cMarca
                    EndIf
                 
                    //Gravando registro
                    RecLock(cAliasTmp, .T.)
                        XX_OK        := cOK
                        XX_CODFIL    := cFilAnt
                        XX_DESCRI    := FWFilialName(cUnidNeg, cFilAnt)
                        XX_CIDENT    := SM0->M0_CIDENT
                        XX_ESTENT    := SM0->M0_ESTENT
                        XX_CGC       := SM0->M0_CGC
                    (cAliasTmp)->(MsUnlock())
                Next
            Next
        Next
         
        //Voltando backups
        cEmpAnt := cEmpBk
        cFilAnt := cFilBk
        RestArea(aAreaM0)
     
    Else
        //Faz a consulta
        cQuery := " SELECT "    + STR_PULA
        cQuery += "    TOP 100 "
        For nAtual := 1 To Len(aCampos)
            cCampoAtu := aCampos[nAtual]
            cQuery += " "+cCampoAtu+","
        Next
        cQuery := SubStr(cQuery, 1, Len(cQuery)-1)    + STR_PULA
        cQuery += " ,"+cAliasPvt+".R_E_C_N_O_ AS XX_RECNUM "    + STR_PULA
        cQuery += " FROM "    + STR_PULA
        cQuery += "   "+RetSQLName(cAliasPvt)+" "+cAliasPvt+" "    + STR_PULA
        cQuery += " WHERE "    + STR_PULA
        cQuery += "   "+cAliasPvt+".D_E_L_E_T_='' " + STR_PULA
        cQuery += "   "+cFiltro+" " + STR_PULA
        cQuery += "   AND ("
        For nAtual := 1 To Len(aCampos)
            cCampoAtu := aCampos[nAtual]
            cQuery += " UPPER("+cCampoAtu+") LIKE '%"+Upper(Alltrim(cGetPesq))+"%' OR"
        Next
        cQuery := SubStr(cQuery, 1, Len(cQuery)-2)
        cQuery += ")"+STR_PULA
        cQuery += " ORDER BY "    + STR_PULA
        cQuery += "   "+cCampoRet
        TCQuery cQuery New Alias "QRY_DAD"
         
        //Percorrendo a estrutura, procurando campos de data
        For nAtual := 1 To Len(aStrut)
            //Se for data
            If aStrut[nAtual][2] == "D"
                TCSetField('QRY_DAD', aStrut[nAtual][1], 'D')
            EndIf
        Next
         
        //Enquanto tiver dados
        While ! QRY_DAD->(EoF())
            cOk := Space(Len(cMarca))
            //Se já existir no retorno, será Ok
            If Alltrim(&("QRY_DAD->"+cCampoRet)) $ cGetReto
                cOk := cMarca
            EndIf
         
            //Gravando registro
            RecLock(cAliasTmp, .T.)
                XX_OK := cOK
                //Percorrendo os campos
                For nAtual := 1 To Len(aCampos)
                    cCampoAtu := aCampos[nAtual]
                    &(cCampoAtu+" := QRY_DAD->"+cCampoAtu)
                Next
                &("XX_RECNUM := cValToChar(QRY_DAD->XX_RECNUM)")
            (cAliasTmp)->(MsUnlock())
         
            QRY_DAD->(DbSkip())
        EndDo
        QRY_DAD->(DbCloseArea())
    EndIf
     
    //Posiciona no topo e atualiza grid
    (cAliasTmp)->(DbGoTop())
    oMAux:oBrowse:Refresh()
Return
 
/*---------------------------------------------------------------------*
 | Func:  fConfirm                                                     |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função de confirmação da rotina                              |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fConfirm()
    //Setando o retorno conforme get e finalizando a tela
    lRetorn := .T.
    __cRetorn := cGetReto
     
    //Se o tamanho for menor, adiciona
    If Len(__cRetorn) < nTamanRet
        __cRetorn += Space(nTamanRet - Len(__cRetorn))
     
    //Senão se for maior, diminui
    ElseIf Len(__cRetorn) > nTamanRet
        __cRetorn := SubStr(__cRetorn, 1, nTamanRet)
    EndIf
     
    oDlgMark:End()
Return
 
/*---------------------------------------------------------------------*
 | Func:  fLimpar                                                      |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função que limpa os dados da rotina                          |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fLimpar()
    //Zerando gets
    cGetPesq := Space(100)
    cGetReto := Space(nTamanRet)
    oGetPesq:Refresh()
    oGetReto:Refresh()
 
    //Atualiza grid
    fPopula()
     
    //Setando o foco na pesquisa
    oGetPesq:SetFocus()
Return
 
/*---------------------------------------------------------------------*
 | Func:  fCancela                                                     |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função de cancelamento da rotina                             |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fCancela()
    //Setando o retorno em branco e finalizando a tela
    lRetorn := .F.
    __cRetorn := Space(nTamanRet)
    oDlgMark:End()
Return
 
/*---------------------------------------------------------------------*
 | Func:  fVldPesq                                                     |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função que valida o campo digitado                           |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fVldPesq()
    Local lRet := .T.
     
    //Se tiver apóstrofo ou porcentagem, a pesquisa não pode prosseguir
    If "'" $ cGetPesq .Or. "%" $ cGetPesq
        lRet := .F.
        MsgAlert("<b>Pesquisa inválida!</b><br>A pesquisa não pode ter <b>'</b> ou <b>%</b>.", "Atenção")
    EndIf
     
    //Se houver retorno, atualiza grid
    If lRet
        fPopula()
    EndIf
Return lRet
 
/*---------------------------------------------------------------------*
 | Func:  fGetMkA                                                      |
 | Autor: Thiago TPR                                                |
 | Data:  19/02/2015                                                   |
 | Desc:  Função que marca o registro                                  |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function fGetMkA(cMarca)
    Local lChecado:= .F.
    Local lFalhou := .F.
     
    //Verificando se o registro foi checado
    DbSelectArea(cAliasTmp)
    lChecado:=XX_OK <> cMarca
    cChave := Alltrim(&(cAliasTmp+"->"+cCampoRet))+";"
     
    //Se for checado
    If lChecado
        //Se o tamanho do retorno +chave for maior que o retorno
        If Len(Alltrim(cGetReto) + cChave) > nTamanRet
            MsgAlert("Tamanho de Retorno Excedido!", "Atenção")
            lFalhou := .T.
         
        //Atualiza chave
        Else
            cGetReto := Alltrim(cGetReto)+cChave
        EndIf
     
    //Senão retira do retorno
    Else
        cGetReto := StrTran(cGetReto, cChave, '')
    EndIf
    cGetReto := cGetReto + Space(nTamanRet - Len(cGetReto))
     
    //Se não houve falhas
    If !lFalhou
        //Gravando a marca
        RecLock( cAliasTmp, .F. )
            XX_OK := IIF( lChecado, cMarca, "" )
        &(cAliasTmp)->(MsUnlock())
    EndIf
     
    oGetReto:Refresh()
    oMAux:oBrowse:Refresh()
Return




//Bibliotecas
  
/*/{Protheus.doc} e
Função Legenda
@type function
@author Washington Miranda Leao. TPR
@since 19/05/2022
@version 1.0
    @example
    u_InveLeganda
/*/
  
Static Function InveLegenda()
    Local aLegenda := {}
//{ "0=Aguardando Contagem", "1=Contagem Realizada", "2=Inventario Gravado", "3=Processado", "4-Todos" }
  

    //Monta as legendas (Cor, Legenda)
    aAdd(aLegenda,{"BR_PRETO",      "Status Zero (0) Aguardando Contagem !"})
    aAdd(aLegenda,{"BR_Amarelo",      "Status UM   (1) Contagem Realizada !"})
    aAdd(aLegenda,{"BR_VERDE",    "Status DOIS (2) Inventario Gravado !"})
    aAdd(aLegenda,{"BR_VERMELHO",   "Status Três (3) Inventário Processado !"})
     
    //Chama a função que monta a tela de legenda
    BrwLegenda("Legenda das Cores dos Status","", aLegenda)
Return
