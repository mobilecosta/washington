                CREATE PROCEDURE TAF613L_##(
                    @IN_FILIAL CHAR('YD_FILIAL'),
                    @IN_PROCESSO CHAR(36),
                    @OUT_RESULT CHAR(1) OUTPUT
                ) AS 

                /*---------------------------------------------------------------------------------------------------------------------
                    Versao      -  <v> Protheus P12 </v>
                    Programa    -  <s> TAF613L </s>
                    Descricao   -  <d> Integra��o entre ERP Livros Fiscais X TAF (SPED)Tabela(SYD)C0A(TAF))-NCM (Nomenclatura comum Mercosul)</d>
                    Entrada     -  <ri> @IN_FILIAL - Filial a ser executada a procedure </ri> 
                    Saida       -  <ro> @OUT_RESULT - Indica o termino da execu��o da procedure: 0 - Falha; 1 - Sucesso </ro>
                    Responsavel :  <r> Washington Miranda Leão </r>
                    Data        :  <dt> 06/09/2023 </dt>
                    Descrição das bases de dados.
                    Nessa issue DSERTAF4-280 Nessa issue iremos trabalhar com o cadastro de NCM (SYD) para gravação do lado do TAF (C0A).
                    SYD(Nomenclatura Comum do Mercosul -Tabela Módulo Fiscal) X C0A(Nomenclatura Comum do Mercosul-Tabela TAF)
                     YD_FILIAL= C0A_FILIAL Codigo da FIlial no Protheus
                     YD_TEC = C0A_CODIGO   Codigo da Nomenclatura Comum  Mercosul
                     YD_DESC_P = C0A_DESCRI Descrição da Nomenclatura Comum Mercosul
                     YD_EX_NCM = C0A_EXNCM Código de Excessão do NCM
                     YD_PER_II = C0A_PERNCM  Percentual do NCM (Preciso perguntar para o especialista de Fiscal se é mesmo este campo)
                      Campos que somente existem na tabela C0A(Nomenclatura Comum Mercosul)
                      C0A_VALIDA->DATA Final Vigência Código
                      C0A_ID->Identificador Registro
                      --------------------------------------------------------------------------------------------------------------------- */
                DECLARE @C0A            CHAR(3)
                DECLARE @V80            CHAR(3)
                DECLARE @SYD            CHAR(3)
                DECLARE @UPDATE         CHAR(1)
                DECLARE @RESULT_V80     CHAR(1)
                DECLARE @NCM            CHAR('C0A_CODIGO')
                DECLARE @FILIAL_C0A     VARCHAR('C0A_FILIAL') 
                DECLARE @FILIAL_V80     VARCHAR('V80_FILIAL')
                DECLARE @FILIAL_SYD     VARCHAR('YD_FILIAL') 
                DECLARE @ID_C0A         VARCHAR('C0A_ID')
                DECLARE @DESCR          VARCHAR('C0A_DESCRI')
                DECLARE @EXNCM          VARCHAR('C0A_EXNCM')
                DECLARE @PERNCM         VARCHAR('C0A_PERNCM')
                DECLARE @DATAVALID      VARCHAR('C0A_VALIDA')
                DECLARE @SEQUENCIA      INTEGER

                BEGIN
                    SELECT @OUT_RESULT      = '0'
                    SELECT @RESULT_V80      = '0'
                    SELECT @UPDATE          = '0'
                    SELECT @C0A             = 'C0A'
                    SELECT @V80             = 'V80'
                    SELECT @SYD             = 'SYD'
                    SELECT @SEQUENCIA       = 0

                    EXEC XFILIAL_## @C0A, @IN_FILIAL, @FILIAL_C0A OUTPUT
                    EXEC XFILIAL_## @V80, @IN_FILIAL, @FILIAL_V80 OUTPUT
                    EXEC XFILIAL_## @SYD, @IN_FILIAL, @FILIAL_SYD OUTPUT

                    DECLARE NCM_UPDATE INSENSITIVE CURSOR FOR
                        SELECT 
                            SYD.YD_TEC NCM, 
                            SYD.YD_DESC_P DESCR,
                            SYD.EX_NCM EXNCM ,
                            SYD.YD_PER_II PERNCM,
                            ' ' DATAVALID
                            FROM SYD### SYD
                            INNER JOIN C0A### C0A
                                ON C0A.D_E_L_E_T_ = ' ' 
                                    AND C0A.C0A_FILIAL = @FILIAL_C0A
                                    AND C0A.C0A_CODIGO = SYD.YD_TEC
                            LEFT JOIN V80### V80
                                ON V80.D_E_L_E_T_ = ' '
                                    AND V80.V80_FILIAL = @FILIAL_V80
                                    AND V80.V80_ALIAS = 'C0A'
                            WHERE SAH.D_E_L_E_T_ = ' '
                                AND SYD.YD_FILIAL = @FILIAL_SYD

                                ##IF_001({|| AllTrim(Upper(TcGetDB())) $ "MSSQL/MSSQL7"})
                                    AND (V80.V80_ALIAS IS NULL 
                                        OR V80.V80_STAMP <= CONVERT(VARCHAR('V80_STAMP'), SYD.S_T_A_M_P_, 21))
                                ##ENDIF_001

                                ##IF_002({|| AllTrim(Upper(TcGetDB())) == "ORACLE"})
                                    AND (V80.V80_ALIAS IS NULL 
                                        OR V80.V80_STAMP <= TO_CHAR(SYD.S_T_A_M_P_, 'DD.MM.YYYY HH24:MI:SS.FF'))
                                ##ENDIF_002

                                ##IF_003({|| AllTrim(Upper(TcGetDB())) == "POSTGRES"})
                                    AND (V80.V80_ALIAS IS NULL 
                                        OR V80.V80_STAMP <= TO_CHAR(SYD.S_T_A_M_P_, 'YYYY-MM-DD HH24:MI:SS.MS'))
                                ##ENDIF_003

                    FOR READ ONLY
                    OPEN NCM_UPDATE

                    FETCH NCM_UPDATE
                        INTO
                            @NCM,
                            @DESCR,
                            @EXNCM,
                            @PERNCM,
                            @DATAVALID
                    BEGIN TRANSACTION

                    WHILE @@FETCH_STATUS = 0 
                        BEGIN
                            SELECT @UPDATE = '1'

                            UPDATE C0A###
                                SET 
                             
                            C0A_CODIGO = @NCM,
                            C0A_DESCRI =  @DESCR,
                            C0A_EXNCM = @EXNCM,
                            C0A_PERNCM  = @PERNCM,
                            C0A_VALIDA  = @DATAVALID
                                    
                                    
                                WHERE D_E_L_E_T_ = ' ' 
                                    AND C0A_FILIAL = @FILIAL_C0A
                                    AND C0A_CODIGO = @NCM

                            FETCH NCM_UPDATE
                                INTO
                            @NCM,
                            @DESCR,
                            @EXNCM,
                            @PERNCM,
                            @DATAVALID
                        END

                    COMMIT TRANSACTION

                    CLOSE NCM_UPDATE
                    DEALLOCATE NCM_UPDATE

                    IF @UPDATE = '1'
                        BEGIN
                            EXEC TAF613G_## @IN_FILIAL, @C0A, @SYD, @RESULT_V80 OUTPUT
                        END

                    SELECT @UPDATE = '0'

                    DECLARE NCM_INSERT INSENSITIVE CURSOR FOR
                        SELECT 
                            SYD.YD_TEC NCM, 
                            SYD.YD_DESC_P DESCR,
                            SYD.EX_NCM EXNCM ,
                            SYD.YD_PER_II PERNCM,
                            ' ' DATAVALID
                                          
                            FROM SYDH### SYD
                            LEFT JOIN C0A### C0A
                                ON C0A.D_E_L_E_T_ = ' '
                                    AND C0A.C0A_FILIAL = @FILIAL_C0A
                                    AND C0A.C0A_CODIGO = SYD.YD_TEC
                            WHERE SYD.D_E_L_E_T_ = ' '
                                AND SYD.YD_FILIAL = @FILIAL_SYD
                                AND C0A.C0A_CODIGO IS NULL

                    FOR READ ONLY    
                    OPEN NCM_INSERT

                    FETCH NCM_INSERT 
                        INTO
                            @NCM,
                            @DESCR,
                            @EXNCM,
                            @PERNCM,
                            @DATAVALID
                    BEGIN TRANSACTION

                    WHILE @@FETCH_STATUS = 0 
                        BEGIN
                            SELECT @UPDATE = '1'
                            SELECT @SEQUENCIA = @SEQUENCIA + 1

                            EXEC TAF613J_## @IN_FILIAL, @IN_PROCESSO, 'TAF613L', 'C0A', @SEQUENCIA, @ID_C0A OUTPUT

                            IF @ID_C0A <> ' '
                                BEGIN
                                    INSERT INTO C0A### (
                                        C0A_FILIAL,
                                        C0A_ID,
                                        C0A_CODIGO,
                                        C0A_DESCRI,
                                        C0A_EXNCM,
                                        C0A_PERNCM,
                                        C0A_VALIDA
                                    ) VALUES (
                                        @FILIAL_C0A,
                                        @ID_C0A,
                                        @NCM,
                                        @DESCR,
                                        @EXNCM,
                                        @PERNCM,
                                        @DATAVALID
                                    )
                                END

                            FETCH NCM_INSERT 
                                INTO
                            @NCM,
                            @DESCR,
                            @EXNCM,
                            @PERNCM,
                            @DATAVALID
                        END

                    COMMIT TRANSACTION

                    CLOSE NCM_INSERT
                    DEALLOCATE NCM_INSERT

                    IF @UPDATE = '1'
                        BEGIN
                            EXEC TAF613G_## @IN_FILIAL, @C0A, @SYD, @RESULT_V80 OUTPUT
                        END

                    SELECT @OUT_RESULT = '1'
                END
