#INCLUDE "TOTVS.CH"

User Function GBESTA01()

Local aParam       := {}     
Local aSelFil      := {}    
Local nI		   := 0

	aAdd(aParam, {1, 'Produto'                   , SPACE(TamSX3('B1_COD')[1])     ,,,"SB1",, 80, .F.})      //-- MV_PAR01
	aAdd(aParam, {1, 'Produto'                   , SPACE(TamSX3('B1_COD')[1])     ,,,"SB1",, 80, .F.})      //-- MV_PAR02
	aAdd(aParam, {1, 'Descrição'                 , SPACE(TamSX3('B1_DESC')[1])     ,,,,, 80, .F.})      //-- MV_PAR01
	aAdd(aParam, {1, 'Descrição'                 , SPACE(TamSX3('B1_DESC')[1])     ,,,,, 80, .F.})      //-- MV_PAR02AR04
	aAdd(aParam, {1, 'Grupo'                     , SPACE(200)     ,,,"SBMARK",, 100, .F.})      //-- MV_PAR05
	aAdd(aParam, {1, 'Marca'                     , SPACE(200)     ,,,"ZZMARK",, 100, .F.})      //-- MV_PAR06


	If ParamBox(aParam, 'Pre-Inventario')
		//Seleciona Filiais 
        aSelFil := AdmGetFil(.T.)	
	
		If Empty(aSelFil)
			Help(" ",1,"GBESTA01",,"Selecione a filial para geração do Mestre de inventário." , 1, 0 )
			Return
		EndIf

     FOR nI	:= 1 to len(aSelFil)   

		MsAguarde({|| GBESTA01(aSelFil[nI]) }, "Gerando Filial: " + aSelFil[nI],"Aguarde",.T.)

	 Next nI 
    EndIF


Return 

Static Function GBESTA01(cFil)

Local cAliasQry1  := GetNextAlias()
Local cGrupo	  :=  STRTRAN(SUBSTR(MV_PAR05,1,len(alltrim(MV_PAR05))-1),";","','")  
Local cMarcas	  :=  STRTRAN(SUBSTR(MV_PAR06,1,len(alltrim(MV_PAR06))-1),";","','")  
Local cWhere      := ""

If ! Empty(cGrupo)
	cWhere += " AND B1_GRUPO IN ('" + cGrupo + "')"
EndIf

If ! Empty(cMarcas)
	cWhere += " AND B1_MARCA IN ('" + cMarcas + "')"
EndIf

IF Empty(cWhere)
	cWhere := "%%"
Else
	cWhere := "%" + cWhere + "%"
EndIf

DbSelectArea("ZZ1")

	BeginSql alias cAliasQry1                                  		

		SELECT B1_COD
			,	B1_DESC
			, 	B1_TIPO
			, 	B1_GRUPO
			, 	B1_UM
			, 	B1_LOCPAD
			, 	B1_CODBAR
			, 	B1_SEGUM				
		FROM %table:SB1%  AS SB1
		WHERE B1_FILIAL = %exp:xFilial("SB1")%	 
			AND B1_COD BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%  
			AND B1_DESC BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
			AND B1_MSBLQL IN (' ', '2') %exp:cWhere%
			AND SB1.D_E_L_E_T_ = '' 	
		ORDER BY B1_COD,B1_LOCPAD	
	EndSql

	DbSelectArea(cAliasQry1)
	(cAliasQry1)->(DBGOTOP())
	
	While(cAliasQry1)->(!EOF())
		BeginSql alias "QRY"                                		
			SELECT MAX(ZZ1_CONTAG) AS ZZ1_CONTAG
			  FROM %table:ZZ1%
			 WHERE ZZ1_FILIAL = %exp:cFil%	AND ZZ1_COD = %exp:cFil% AND D_E_L_E_T_ = ''
		EndSql
		M->ZZ1_CONTAG := QRY->ZZ1_CONTAG
		If Empty(M->ZZ1_CONTAG)
			M->ZZ1_CONTAG := "001'"
		Else
			M->ZZ1_CONTAG := Soma1(M->ZZ1_CONTAG)
		EndIf
		QRY->(DbCloseArea())
	    ZZ1->(DbSetOrder(1))//ZZ1_FILIAL+ZZ1_COD+ZZ1_LOCAL
		iF 	!ZZ1->(DBSeek(xFilial("ZZ1")+ZZ1->ZZ1_FILIAL+ZZ1->ZZ1_COD+ZZ1->ZZ1_LOCAL))
						
		RecLock("ZZ1", .T.)
		ZZ1->ZZ1_FILIAL := cFil
		ZZ1->ZZ1_COD 	:= (cAliasQry1)->B1_COD
		ZZ1->ZZ1_DESC 	:= (cAliasQry1)->B1_DESC
		ZZ1->ZZ1_TIPO 	:= (cAliasQry1)->B1_TIPO
		ZZ1->ZZ1_LOCAL 	:= (cAliasQry1)->B1_LOCPAD
		ZZ1->ZZ1_DOC   	:= GetSXENum('ZZ1', 'ZZ1_DOC')
		ZZ1->ZZ1_QUANT 	:= 0
		ZZ1->ZZ1_QTSEGU := 0
		ZZ1->ZZ1_GRUPO  := (cAliasQry1)->B1_GRUPO
		ZZ1->ZZ1_CODBAR	:= (cAliasQry1)->B1_CODBAR		
		ZZ1->ZZ1_STATUS	:= "0"
		ZZ1->ZZ1_ORIGEM	:= "GBESTA01"
		ZZ1->ZZ1_DATA 	:= dDatabase
		ZZ1->ZZ1_CONTAG := M->ZZ1_CONTAG
		MsUnlock()	
	Endif
		ConfirmSX8()
	
		(cAliasQry1)->( dbSkip() )
	EndDo
Return
