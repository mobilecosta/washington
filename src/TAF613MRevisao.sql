                    CREATE PROCEDURE TAF613M_##(
                        @IN_FILIAL CHAR('F4_FILIAL'),
                       @IN_MV_SPEDNAT FLOAT
                        @IN_PROCESSO CHAR(36),
                        @OUT_RESULT CHAR(1) OUTPUT
                    ) AS 

                    /*---------------------------------------------------------------------------------------------------------------------
                        Versao      -  <v> Protheus P12 </v>
                        Programa    -  <s> TAF613M </s>
                        Descricao   -  <d> Integra��o entre ERP Livros Fiscais X TAF (SPED)Tabela(SF4)CD1/C1N(TAF))-NOP (Natureza de Operação)</d>
                        Entrada     -  <ri> @IN_FILIAL - Filial a ser executada a procedure </ri> 
                        Saida       -  <ro> @OUT_RESULT - Indica o termino da execu��o da procedure: 0 - Falha; 1 - Sucesso </ro>
                        Responsavel :  <r> Washington Miranda Leão </r>
                        Data        :  <dt> 13/09/2023 </dt>
                        Descrição das bases de dados.
                        SF4(Cadastro de TES-Tabela protheus) X CD1(Natureza da Operação/Prestação) X C1N(TAF) Natureza de Operação. 
                         F4_FILIAL= CD1_FILIAL Codigo da FIlial no Protheus
                         Nessa issue DSERTAF4-264 iremos trabalhar com o cadastro de natureza de operação (CD1/SF4) para enviar para o TAF (C1N).
                
                        Tabela SF4(Cadastro de TES)

                         Campos.

                        F4_FILIAL 
                        F4_NATOPER C -10  Natureza de Operação
                        F4_TEXTO   C  - 20  Codigo do Texto Padrão
                        

                        Tabela CD1(Natureza da Operação/Prestação)
                        Campos

                        CD1_FILIAL  Filial
                        CD1_CODNAT C-10- Codigo da Natureza de Operação
                        CD1_DESCR -C-50  Descrição da Natureza de Operação
                        D_E_L_E_T    Marca como registro deletado

                        Abaixo o relacionamento entre a tabela SF4 e CD1
                         CD1_FILIAL=F4_FILIAL
                         CD1_CODNAT=F4_NATOPER
                         CD1_DESCR=F4_TEXTO


                        Tabela C1N(TAF) Natureza de Operação.
                        Campos.
                        
                         C1N_FILIAL C- 6 - Filial
                         C1N_ID C - 36- ID- Identificador Registro
                        * C1N_CODNAT- C- 8 - Natureza de Operação
                        * C1N_DESNAT  C- 2200 Desc.Natureza operação
                        * C1N_NATECF C- 5 -Natureza da Operação ECF
                        * C1N_DNATEC C- 220- Descrição Natureza Operação ECF
                        * C1N_CTISS  C-09 - Código CTISS
                        * C1N_CODMOT C-02- Cód. Motivo Não Retenção
                        * C1N_DESMOT C-60- Descrição do Motivo
                        * C1N_CODREG C-02- Código Regime Especial Trib
                        * C1N_DESREG C-60- Descrição Regime Especial Trib
                        * C1N_CODTIP C-02- Código Tipo de Negócio.
                        * C1N_DESTIP C-60- Descrição Tipo de Negócio.
                        * C1N_CODSIT C-02- Código Sit.Especial Resp
                        * C1N_DESSIT C-60- Desc.Sit. Especial.Resp
                        * C1N_CODEXI C-02- Cód. Exigibilidade ISSQN
                        * C1N_DECEXI C-80- Descrição Exi. ISSQN
                        * C1N_OBJOPE C- 02 Objetivo da operação
                        * C1N_CODANP C- 07 Código da operação ANP
                        * C1N_DESANP C- 220 - Descrição do código ANP
                        * C1N_STAMP  C-23 - Stamp- Controle de Integração
                        
                                          

                        


                        Abaixo o relacionamento entre a tabela CD1 X C1N

                        C1N_FILIAL=CD1_FILIAL
                        C1N_CODNAT=CD1_CODNAT
                        C1N_NATECF=CD1_DESCR                      
                        Nessa issue iremos trabalhar com o cadastro de natureza de operação (CD1/SF4) para enviar para o TAF (C1N).                      
                       
                       Exemplo de Query passada pleo Melkz.

                                             
                                             
                     ----------------------------------------------------------------------------------------------------------------------- */
                    DECLARE @C1N            CHAR(3) // Natureza de Operação
                    DECLARE @V80            CHAR(3)
                    DECLARE @CD1            CHAR(3)// 
                    DECLARE @SF4            CHAR(3)
                    DECLARE @UPDATE         CHAR(1)
                    DECLARE @RESULT_V80     CHAR(1)
                    DECLARE @NATOP_CD1      VARCHAR('CD1_CODNAT')
                    DECLARE @NATOP_C1N      VARCHAR('C1N_CODNAT')
                    DECLARE @NATOP_SF4      VARCHAR('F4_NATOPER')
                    DECLARE @CFOP_SF4       VARCHAR('F4_CF')
                    DECLARE @FILIAL_CD1     VARCHAR('CD1_FILIAL')
                    DECLARE @FILIAL_C1N     VARCHAR('C1N_FILIAL') 
                    DECLARE @FILIAL_V80     VARCHAR('V80_FILIAL')
                    DECLARE @FILIAL_SF4     VARCHAR('F4_FILIAL')
                    DECLARE @DESCR_C1N      VARCHAR('C1N_DESNAT')
                    DECLARE @DESCR_CD1      VARCHAR('CD1_DESCR')
                    DECLARE @DESCRF4_TEXTO  VARCHAR('F4_TEXTO')
                    DECLARE @ID_C1N         VARCHAR('C1N_ID')
                    DECLARE @SEQUENCIA      INTEGER

                    BEGIN
                        SELECT @OUT_RESULT      = '0'
                        SELECT @RESULT_V80      = '0'
                        SELECT @UPDATE          = '0'
                        SELECT @CD1             = 'CD1'
                        SELECT @C1N             = 'C1N'
                        SELECT @V80             = 'V80'
                        SELECT @SF4             = 'SF4'
                        SELECT @SEQUENCIA       = 0

                        EXEC XFILIAL_## @CD1, @IN_FILIAL, @FILIAL_CD1 OUTPUT
                        EXEC XFILIAL_## @CN1, @IN_FILIAL, @FILIAL_CN1 OUTPUT
                        EXEC XFILIAL_## @V80, @IN_FILIAL, @FILIAL_V80 OUTPUT
                        EXEC XFILIAL_## @SF4, @IN_FILIAL, @FILIAL_SF4 OUTPUT

                        DECLARE NATOP_UPDATE INSENSITIVE CURSOR FOR
                             SELECT SF4.F4_CODIGO, SF4.F4_NATOPE, SF4.F4_TEXTO, SF4.F4_CF, CD1.CD1_DESCR,
                             SX5.X5_DESCRI FROM SF4### SF4
                            LEFT JOIN CD1### CD1
                            ON CD1.D_E_L_E_T = ' ' AND CD1.CD1_FILIAL = @FILIAL_SF4 AND CD1.CD1_CODNAT = SF4.F4_CF
                            LEFT JOIN SX5### SX5
                            ON SX5.D_E_L_E_T = ' ' AND SX5.X5_FILIAL = @FILIAL_SF4  AND SX5.X5_TABELA = '13' AND SX5.SX5_X5_CHAVE = @CFOP_SF4 
                            WHERE SF4.D_E_L_E_T = ' ' SF4.SF4_FILIAL = ' '

                            IF F4_CF <> ' '
                                BEGIN
                                SELECT @NATOP_CD1 = F4_CF 
                                SELECT @DESCRF4_TEXTO = CD1_DESCR
                            END
                            ELSE IF @IN_MV_SPEDNAT = '.F.'
                                    BEGIN
                                    SELECT @NATOP_CD1  = F4_CF 
                                    SELECT @DESCR_CD1 = F4_TEXTO
                            END
                            ELSE IF @IN_MV_SPEDNAT = '.T.'
                                    BEGIN
                                    SELECT @NATOP_CD1 = F4_CF 
                                    SELECT @DESCR_CD1 = X5_DESCRI 
                            END
 
                                INNER JOIN CN1### CN1
                                        AND C1N.C1N_FILIAL = @FILIAL_CN1
                                        AND C1N.C1N_CODNAT = @NATOP_CD1
                                        AND C1N.C1N_DESNAT = @DESCR_CD1 
                                LEFT JOIN V80### V80
                                    ON V80.D_E_L_E_T_ = ' '
                                        AND V80.V80_FILIAL = @FILIAL_V80
                                        AND V80.V80_ALIAS = 'C1N'
                                        
                                WHERE SF4.D_E_L_E_T_ = ' '
                                    AND SF4.F4_FILIAL = @FILIAL_CD1

                                    ##IF_001({|| AllTrim(Upper(TcGetDB())) $ "MSSQL/MSSQL7"})
                                        AND (V80.V80_ALIAS IS NULL 
                                            OR V80.V80_STAMP <= CONVERT(VARCHAR('V80_STAMP'), C1N.S_T_A_M_P_, 21))
                                    ##ENDIF_001

                                    ##IF_002({|| AllTrim(Upper(TcGetDB())) == "ORACLE"})
                                        AND (V80.V80_ALIAS IS NULL 
                                            OR V80.V80_STAMP <= TO_CHAR(C1N.S_T_A_M_P_, 'DD.MM.YYYY HH24:MI:SS.FF'))
                                    ##ENDIF_002

                                    ##IF_003({|| AllTrim(Upper(TcGetDB())) == "POSTGRES"})
                                        AND (V80.V80_ALIAS IS NULL 
                                            OR V80.V80_STAMP <= TO_CHAR(C1N.S_T_A_M_P_, 'YYYY-MM-DD HH24:MI:SS.MS'))
                                    ##ENDIF_003

                        FOR READ ONLY
                        OPEN NATOP_UPDATE

                        FETCH NATOP_UPDATE
                            INTO
                                @NATOP_CD1,
                                @DESCR_CD1 
                                
                        BEGIN TRANSACTION

                        WHILE @@FETCH_STATUS = 0 
                            BEGIN
                                SELECT @UPDATE = '1'

                                UPDATE C1N###
                                    SET 
                                
                                CN1_CODIGO = @NATOP_CD1,
                                C1N_DESNAT =  @DESCR
                                        
                                        
                                    WHERE D_E_L_E_T_ = ' ' 
                                        AND C1N_FILIAL = @FILIAL_C1N
                                        AND C1N_CODIGO = @DESCR_CD1

                                FETCH NATOP_UPDATE
                                    INTO
                                @NATOP_C1N,
                                @DESCR_C1N 
                                
                            END

                        COMMIT TRANSACTION

                        CLOSE NATOP_UPDATE
                        DEALLOCATE NATOP_UPDATE

                        IF @UPDATE = '1'
                            BEGIN
                                EXEC TAF613G_## @IN_FILIAL, @CD1, @SF4, @RESULT_V80 OUTPUT
                            END

                        SELECT @UPDATE = '0'

                        DECLARE NATOP_INSERT INSENSITIVE CURSOR FOR
                            SELECT 
                                SELECT SF4.F4_CODIGO, SF4.F4_NATOPE, SF4.F4_TEXTO, SF4.F4_CF, CD1.CD1_DESCR,
                             SX5.X5_DESCRI FROM SF4### SF4
                            LEFT JOIN CD1### CD1
                            ON CD1.D_E_L_E_T = ' ' AND CD1.CD1_FILIAL = @FILIAL_SF4 AND CD1.CD1_CODNAT = SF4.F4_CF
                            LEFT JOIN SX5### SX5
                            ON SX5.D_E_L_E_T = ' ' AND SX5.X5_FILIAL = @FILIAL_SF4  AND SX5.X5_TABELA = '13' AND SX5.SX5_X5_CHAVE = @CFOP_SF4 
                            WHERE SF4.D_E_L_E_T = ' ' SF4.SF4_FILIAL = ' '

                            IF F4_CF <> ' '
                                BEGIN
                                SELECT @NATOP_CD1 = F4_CF 
                                SELECT @DESCRF4_TEXTO = CD1_DESCR
                            END
                            ELSE IF @IN_MV_SPEDNAT = '.F.'
                                    BEGIN
                                    SELECT @NATOP_CD1  = F4_CF 
                                    SELECT @DESCR_CD1 = F4_TEXTO
                            END
                            ELSE IF @IN_MV_SPEDNAT = '.T.'
                                    BEGIN
                                    SELECT @NATOP_CD1 = F4_CF 
                                    SELECT @DESCR_CD1 = X5_DESCRI 
                            END
 
                                INNER JOIN CN1### CN1
                                        AND C1N.C1N_FILIAL = @FILIAL_CN1
                                        AND C1N.C1N_CODNAT = @NATOP_CD1
                                        AND C1N.C1N_DESNAT = @DESCR_CD1 
                                LEFT JOIN V80### V80
                                    ON V80.D_E_L_E_T_ = ' '
                                        AND V80.V80_FILIAL = @FILIAL_V80
                                        AND V80.V80_ALIAS = 'C1N'
                                        
                                WHERE SF4.D_E_L_E_T_ = ' '
                                    AND SF4.F4_FILIAL = @FILIAL_CD1


                        FOR READ ONLY    
                        OPEN NATOP_INSERT

                        FETCH NATOP_INSERT 
                            INTO
                                @NATOP_C1N,
                                @DESCR_C1N 
                        BEGIN TRANSACTION

                        WHILE @@FETCH_STATUS = 0 
                            BEGIN
                                SELECT @UPDATE = '1'
                                SELECT @SEQUENCIA = @SEQUENCIA + 1

                                EXEC TAF613J_## @IN_FILIAL, @IN_PROCESSO, 'TAF613M', 'C1N', @SEQUENCIA, @ID_C1N OUTPUT

                                IF @C1N_ID <> ' '
                                    BEGIN
                                        INSERT INTO CD1### (
                                          C1N_FILIAL,
                                          C1N_CODNAT,
                                          C1N_DESNAT
                                                                              
                                           
                                        ) VALUES (
                                            @FILIAL_C1N,
                                            @NATOP_C1N,
                                            @DESCR_C1N           
                                        )
                                    END

                                FETCH NATOP_INSERT 
                                    INTO
                                @FILIAL_C1N,
                                @NATOP_C1N,
                                @DESCR_C1N
                            END

                        COMMIT TRANSACTION

                        CLOSE NATOP_INSERT
                        DEALLOCATE NCM_INSERT

                        IF @UPDATE = '1'
                            BEGIN
                                EXEC TAF613G_## @IN_FILIAL, @C1N, @CD1, @RESULT_V80 OUTPUT
                            END

                        SELECT @OUT_RESULT = '1'
                    END
