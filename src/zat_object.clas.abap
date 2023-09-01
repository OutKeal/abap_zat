CLASS zat_object DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor .
    CLASS-METHODS create
      IMPORTING
        VALUE(is_head)   TYPE zats_bapi_head
        VALUE(it_item)   TYPE zatts_bapi_item
      EXPORTING
        VALUE(e_atno)    TYPE zatt_head-atno
        VALUE(e_status)  TYPE zatt_head-status
        VALUE(et_return) TYPE bapiret2_t
      RETURNING
        VALUE(rv_at)     TYPE REF TO zat_object
      EXCEPTIONS
        error .
    CLASS-METHODS post
      IMPORTING
        VALUE(i_type)    TYPE zatt_head-type
        VALUE(i_atno)    TYPE zatt_head-atno
        VALUE(i_budat)   TYPE zatt_head-budat
      EXPORTING
        VALUE(e_status)  TYPE zatt_head-status
        VALUE(et_return) TYPE bapiret2_t .
    CLASS-METHODS cancel
      IMPORTING
        VALUE(i_atno)    TYPE zatt_head-atno
        VALUE(i_type)    TYPE zatt_head-type
        VALUE(i_budat)   TYPE zatt_head-budat
      EXPORTING
        VALUE(et_return) TYPE bapiret2_t .
    METHODS clear .
protected section.

  data GS_HEAD type ZATT_HEAD .
  data GS_TYPE type ZATT_TYPE .
  data GS_ITEM_STEP type ZATT_ITEM_STEP .
  data G_ERROR type ABAP_BOOL .
  data G_ATNO type ZATT_HEAD-ATNO .
  data G_TYPE type ZATT_HEAD-TYPE .
  data G_MSGNR type CHAR10 .
  data G_TIMES type INT1 .
  data G_MBLNR type MBLNR .
  data G_MJAHR type MJAHR .
  data G_BUDAT type BUDAT .
  data:
    gt_type      TYPE TABLE OF zatt_type .
  data:
    gt_control   TYPE TABLE OF zatt_control .
  data:
    gt_step      TYPE TABLE OF zatt_step .
  data:
    gt_step_rule TYPE TABLE OF zatt_step_rule .
  data:
    gt_item      TYPE TABLE OF zatt_item .
  data:
    gt_item_step TYPE TABLE OF zatt_item_step .
  data:
    gt_message   TYPE TABLE OF zatt_message .
  data:
    gt_return    TYPE TABLE OF bapiret2 .
  constants C_NR type INT1 value 1 ##NO_TEXT.

  methods ADD_MSG
    importing
      value(MSGTY) type SY-MSGTY
      value(MSGID) type SY-MSGID
      value(MSGNO) type SY-MSGNO
      value(MSGV1) type SY-MSGV1 optional
      value(MSGV2) type SY-MSGV2 optional
      value(MSGV3) type SY-MSGV3 optional
      value(MSGV4) type SY-MSGV4 optional .
  methods BINARY_RELATION
    importing
      value(IS_ITEM_STEP) type ZATT_ITEM_STEP .
private section.

  methods CLEAR_BUFFER .
  methods GET_DATA .
  methods GET_CONFIG .
  methods CHECK_EXORD .
  methods CHECK_HEAD_DATA .
  methods CHECK_ITEM_DATA .
  methods INIT .
  methods INIT_HEAD .
  methods INIT_INIT_ITEM_STEP .
  methods INIT_ITEM .
  methods INIT_ITEM_TEXT .
  methods MOVE_HEAD_TO_ITEM .
  methods GET_NEXT_ATNO
    returning
      value(R_ATNO) type ZATT_HEAD-ATNO .
  methods UPDATE_HEAD_STATUS
    importing
      !I_STATUS type ZATT_HEAD-STATUS .
  methods UPDATE_ITEM_STEP
    changing
      !IS_ITEM_STEP type ZATT_ITEM_STEP .
  methods SAVE_DATA .
  methods GO_STEP .
  methods CANCEL_STEP .
  methods GO_SINGLE .
  methods CANCEL_SINGLE .
  methods PROGRESSBAR_SHOW
    importing
      !I_CURRENT type I
      !I_TOTAL type I
      !I_MSG type STRING optional .
  methods LOCK .
  methods UNLOCK .
ENDCLASS.



CLASS ZAT_OBJECT IMPLEMENTATION.


  METHOD add_msg.

    g_error = COND abap_bool( WHEN msgty = 'E' OR msgty =  'A' THEN abap_true ELSE abap_false ).

    MESSAGE ID msgid
    TYPE msgty
    NUMBER msgno
    INTO  DATA(l_message)
          WITH msgv1 msgv2 msgv3 msgv4.

    APPEND VALUE #( type = msgty
    id = msgid
    number = msgno
    message_v1 = msgv1
    message_v2 = msgv2
    message_v3 = msgv3
    message_v4 = msgv4
    message = l_message
    ) TO gt_return.

    CHECK g_times IS NOT INITIAL.

    APPEND VALUE #( atno     =    gs_head-atno
    times    = g_times
    step     = gs_item_step-step
    msgty    = msgty
    msgid    = msgid
    msgno    = msgno
    msgv1    = msgv1
    msgv2    = msgv2
    msgv3    = msgv3
    msgv4    = msgv4
    message  = l_message
    ernam    = sy-uname
    erdat    = sy-datum
    erzet    = sy-uzeit
    ) TO gt_message.
  ENDMETHOD.


  METHOD binary_relation.
    DATA:ls_borident1 TYPE borident.
    DATA:ls_borident2 TYPE borident.
    CHECK is_item_step-docnr IS NOT INITIAL.

    ls_borident1-objtype = 'ZAT'.
    ls_borident1-objkey = gs_head-atno.

    CASE is_item_step-step_type.
      WHEN 'MB' OR 'VL_GI'.
        ls_borident2 = VALUE #( objkey = is_item_step-docnr && is_item_step-cjahr
        objtype = 'BUS2017' ).
      WHEN 'PO_CRE'.
        ls_borident2 = VALUE #( objkey = is_item_step-docnr
        objtype = 'BUS2012' ).
      WHEN 'SO_CRE'.
        ls_borident2 = VALUE #( objkey = is_item_step-docnr
        objtype = 'VBAK' ).
      WHEN 'STO_VL_CRE' OR 'SO_VL_CRE'.
        ls_borident2 = VALUE #( objkey = is_item_step-docnr
        objtype = 'LIKP' ).
    ENDCASE.

    CALL FUNCTION 'BINARY_RELATION_CREATE'
      EXPORTING
        obj_rolea      = ls_borident1
        obj_roleb      = ls_borident2
        relationtype   = 'VORL'
      EXCEPTIONS
        no_model       = 1
        internal_error = 2
        unknown        = 3
        OTHERS         = 4.
  ENDMETHOD.


  METHOD check_exord.
    CHECK gs_head-exord IS NOT INITIAL.

    SELECT SINGLE atno FROM zatt_head
    WHERE exord = @gs_head-exord
    AND type = @g_type
    AND status <> 'D'
    INTO @DATA(l_atno).

    IF sy-subrc EQ 0.
      DATA(l_text) = |外部单号{ gs_head-exord }已重复，请检查输入。单号为{ l_atno }|.
      add_msg( EXPORTING msgty = 'E'  msgid = 'ZAT' msgno = '000' msgv1 = 'L_TEXT' ).
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD check_head_data.

    DATA rule TYPE TABLE OF zats_check_rule .
    DATA ret TYPE TABLE OF bapiret2 .
    CLEAR rule[].
    CLEAR ret[].

    rule = VALUE #( FOR ls_control IN gt_control
                              WHERE ( type = g_type AND fieldalv = 'HEAD' )
                              ( fieldname = ls_control-fieldname
                              rollname = ls_control-rollname
                              notnull = ls_control-requi
                              ddtext = ls_control-coltext ) ).

    DELETE rule WHERE rollname IS INITIAL AND notnull IS INITIAL.

    CALL FUNCTION 'ZAT_CHECK_VALUE'
      EXPORTING
        line = gs_head
      TABLES
        rule = rule
        ret  = ret.

    LOOP AT ret INTO DATA(l_ret).
      add_msg( msgty = l_ret-type
         msgid = l_ret-id
         msgno = l_ret-number
         msgv1 = l_ret-message_v1
         msgv2 = l_ret-message_v2
         msgv3 = l_ret-message_v3
         msgv4 = l_ret-message_v4 ).
    ENDLOOP.
  ENDMETHOD.


  METHOD check_item_data.
    DATA rule TYPE TABLE OF zats_check_rule .
    DATA ret TYPE TABLE OF bapiret2 .
    CLEAR rule[].
    CLEAR ret[].

    LOOP AT gt_control INTO DATA(ls_control) WHERE type = g_type AND fieldalv = 'HEAD'.
      IF ls_control-rollname IS NOT INITIAL OR ls_control-requi IS NOT INITIAL.
        APPEND VALUE #( fieldname = ls_control-fieldname
        rollname = ls_control-rollname
        notnull = ls_control-requi
        ddtext = ls_control-coltext
        ) TO rule.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'ZAT_CHECK_VALUE'
      TABLES
        tab  = gt_item[]
        rule = rule
        ret  = ret.

    LOOP AT ret INTO DATA(l_ret).
      add_msg( EXPORTING msgty = l_ret-type msgid = l_ret-id msgno = l_ret-number
        msgv1 = l_ret-message_v1
        msgv2 = l_ret-message_v2
        msgv3 = l_ret-message_v3
        msgv4 = l_ret-message_v4 ).

    ENDLOOP.

  ENDMETHOD.


  METHOD clear.
    CLEAR: gt_item ,
    gt_control,
    gt_type ,
    gt_step,
    gt_step_rule,
    gt_item_step,
    gt_message,
    gt_return.

    CLEAR: gs_head,
    gs_type ,
    gs_item_step.

    CLEAR :g_budat,
    g_atno,
    g_type,
    g_error,
    g_msgnr,
    g_times,
    g_mblnr,
    g_mjahr.
  ENDMETHOD.


  METHOD constructor.
    clear( ).

    DEFINE return_error.
      IF rv_at->g_error = 'X'.
        et_return = rv_at->gt_return.
        FREE rv_at.
        RETURN.
      ENDIF.
    END-OF-DEFINITION.
  ENDMETHOD.


  METHOD create.

    CREATE OBJECT rv_at."实例化对象

    rv_at->g_type = is_head-type."全局参数赋值
    rv_at->g_budat = is_head-budat.
    MOVE-CORRESPONDING is_head TO rv_at->gs_head.
    MOVE-CORRESPONDING it_item TO rv_at->gt_item.

    rv_at->get_config( )."读取配置
    return_error.

    rv_at->check_exord( )."校验单号类型+唯一性
    return_error.

    rv_at->check_head_data( )."校验抬头信息
    return_error.

    rv_at->check_item_data( )."校验项目数据
    return_error.

    rv_at->g_atno = rv_at->get_next_atno( )."获取对象单号
    return_error.

    rv_at->init( )."初始化单据
    rv_at->save_data( )."保存单据

    IF rv_at->gs_type-immed = 'X'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      rv_at->go_step( )."过账
    ENDIF.

    et_return = rv_at->gt_return.
    e_atno = rv_at->gs_head-atno.
    e_status = rv_at->gs_head-status.

  ENDMETHOD.


  METHOD get_config.

    SELECT SINGLE * FROM zatt_type
    WHERE type = @g_type
    INTO @gs_type.
    IF sy-subrc NE 0.
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '001' ).
      RETURN.
    ENDIF.

    SELECT  * FROM zatt_control
    WHERE type = @g_type
    INTO TABLE @gt_control.
    IF sy-subrc NE 0.
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '001' ).
      RETURN.
    ENDIF.

    SELECT  * FROM zatt_step
    WHERE type = @g_type
    INTO TABLE @gt_step.
    IF sy-subrc NE 0.
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '001' ).
      RETURN.
    ENDIF.

    SELECT  * FROM zatt_step_rule
    WHERE type = @g_type
    INTO TABLE @gt_step_rule.
    IF sy-subrc NE 0.
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '001' ).
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD get_next_atno.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZATNO'
      IMPORTING
        number                  = r_atno
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = '单号获取错误' ).
    ELSE.
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.


  METHOD go_single.
    DATA:lt_step_rule TYPE TABLE OF zatt_step_rule.
    READ TABLE gt_step INTO DATA(ls_step) WITH KEY type = gs_item_step-type step = gs_item_step-step.
    CHECK sy-subrc EQ 0.

    lt_step_rule[] = VALUE #( FOR wa IN gt_step_rule
    WHERE ( type = ls_step-type AND step = ls_step-step ) ( wa ) ).

    clear_buffer( ).

    zat_go=>go( step = gs_item_step
    head = gs_head
    item = gt_item[]
    item_step = gt_item_step[]
    )->call_bapi( IMPORTING ret = DATA(ret)  ) .

    IF ret-msgty EQ 'E'. "bapi配置调用处理失败
      g_error = 'X'.
      gs_item_step-status = 'E'.
      MESSAGE ID 'ZAT' TYPE 'S' NUMBER ret-msgno INTO gs_item_step-msgtx.
      add_msg( msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = |{ gs_item_step-msgtx }| ).
      update_item_step( CHANGING is_item_step = gs_item_step ).
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
      RETURN.
    ENDIF.

    LOOP AT ret-return INTO DATA(ls_return) .
      add_msg( msgty = ls_return-type
                        msgid = ls_return-id
                        msgno = ls_return-number
                        msgv1 = ls_return-message_v1
                        msgv2 = ls_return-message_v2
                        msgv3 = ls_return-message_v3
                        msgv4 = ls_return-message_v4 ) .
    ENDLOOP.

    IF g_error = 'X'."BAPI返回失败
      ROLLBACK WORK.
      gs_item_step-status = 'E'.
      gs_item_step-msgtx = |凭证创建失败|.
*    gs_item_step-docnr = e_vbeln.
      add_msg( msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = |{ gs_item_step-msgtx }|  ).
      update_item_step( CHANGING is_item_step = gs_item_step ).
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
    ELSE.
      gs_item_step-status = 'C'.
      gs_item_step-msgtx = | 凭证{ ret-docnr } 创建成功|.
      gs_item_step-docnr = ret-docnr.
      gs_item_step-cjahr = ret-cjahr.
      gs_item_step-objtype = ret-objtype.
      add_msg( msgty = 'S' msgid = 'ZAT' msgno = '000' msgv1 = |{ gs_item_step-msgtx }|  ).
      update_item_step( CHANGING is_item_step = gs_item_step ).
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
    ENDIF.
  ENDMETHOD.


  METHOD go_step.
    CLEAR g_times.
    IF NOT ( gs_head-status = 'A' OR gs_head-status = 'E' ).
      add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = '无法执行' ).
      RETURN.
    ENDIF.

    SORT gt_item_step BY step.
    SELECT SINGLE MAX( times ) FROM zatt_message
                WHERE atno = @gs_head-atno
                GROUP BY atno
                INTO @g_times.

    ADD 1 TO g_times.

    add_msg( EXPORTING msgty = 'S' msgid = 'ZAT' msgno = '000' msgv1 = |--自动交易{ gs_head-atno }正在执行--| ).

    LOOP AT gt_item_step INTO gs_item_step
       WHERE status = 'A' OR status = 'E'.
      progressbar_show( i_current = sy-tabix i_total = lines( gt_item_step ) ).
      CASE gs_item_step-step_type.
        WHEN 'BAPI'.
          go_single( ).
        WHEN OTHERS.
          add_msg( EXPORTING msgty = 'E'  msgid = 'ZAT' msgno = '000' msgv1 = 'OO只支持BAPI模式' ).
      ENDCASE.

      MODIFY gt_item_step FROM gs_item_step.
      IF g_error = 'X'.
        RETURN.
      ENDIF.
    ENDLOOP.
    IF g_error = ''.
      update_head_status( 'C' ).
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.


  METHOD init.
    init_head( )."初始化抬头
    init_item( )."初始化项目
    init_item_text( )."初始化文本
    init_init_item_step( )."初始化单据的步骤处理过程
    move_head_to_item( )."将抬头必填赋值到项目对应字段
  ENDMETHOD.


  METHOD init_head.
    MOVE-CORRESPONDING gs_type TO gs_head.
    LOOP AT gt_control INTO DATA(ls_control) WHERE type = g_type AND fieldalv = 'HEAD' AND zdefault <> ''.
      ASSIGN COMPONENT ls_control-fieldname OF STRUCTURE gs_head TO FIELD-SYMBOL(<fs_value>).
      IF sy-subrc EQ 0.
        IF <fs_value> IS INITIAL.
          <fs_value> = ls_control-zdefault.
        ENDIF.
      ENDIF.
    ENDLOOP.

    gs_head = VALUE #( BASE gs_head
    atno = g_atno
    budat = g_budat
    status = 'A'
    erdat = sy-datum
    erzet =  sy-uzeit
    ernam = sy-uname
    ).
  ENDMETHOD.


  METHOD init_init_item_step.
    LOOP AT gt_step INTO DATA(ls_step).
      MOVE-CORRESPONDING ls_step TO gs_item_step.
      gs_item_step = VALUE #( BASE gs_item_step
      status = 'A'
      atno = g_atno ).

      APPEND gs_item_step TO gt_item_step.
      CLEAR gs_item_step.
    ENDLOOP.
  ENDMETHOD.


  METHOD init_item.
    DATA:l_atnr TYPE mb_line_id.
    LOOP AT gt_control INTO DATA(ls_control) WHERE type = g_type AND fieldalv = 'ITEM' AND zdefault <> ''.
      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<fs_item>).
        ASSIGN COMPONENT ls_control-fieldname OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fs_value>).
        IF sy-subrc EQ 0.
          IF <fs_value> IS INITIAL.
            <fs_value> = ls_control-zdefault.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    CLEAR l_atnr.
    CLEAR gs_head-menge.
    CLEAR gs_head-amount.

    LOOP AT gt_item ASSIGNING <fs_item> .
      IF <fs_item>-menge IS INITIAL.
        CLEAR <fs_item>-amount.
      ELSE.
        IF <fs_item>-amount IS INITIAL.
          <fs_item>-amount = <fs_item>-menge * <fs_item>-price.
        ELSEIF <fs_item>-price IS INITIAL.
          <fs_item>-price = <fs_item>-amount / <fs_item>-menge.
        ENDIF.
      ENDIF.

      <fs_item>-atno = g_atno.
      ADD c_nr TO l_atnr.
      <fs_item>-atnr = l_atnr.

      ADD <fs_item>-menge TO gs_head-menge.
      ADD <fs_item>-amount TO gs_head-amount.
    ENDLOOP.
  ENDMETHOD.


  METHOD init_item_text.

    SELECT a~matnr,a~meins,t~maktx
          FROM mara AS a LEFT JOIN makt AS t
          ON a~matnr = t~matnr
          AND t~spras = @sy-langu
          INNER JOIN @gt_item AS b ON a~matnr = b~matnr
          INTO TABLE @DATA(lt_mara).

    SORT lt_mara BY matnr.

    LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<fs_item>).
      READ TABLE lt_mara INTO DATA(ls_mara) WITH KEY matnr = <fs_item>-matnr BINARY SEARCH.
      IF sy-subrc EQ 0.
        <fs_item>-meins = COND meins( WHEN <fs_item>-meins IS INITIAL THEN ls_mara-meins ).
        <fs_item>-maktx = COND maktx( WHEN <fs_item>-maktx IS INITIAL THEN ls_mara-maktx ).
      ELSE.
        add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = |物料号{ <fs_item>-matnr }不存在| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD move_head_to_item.
    LOOP AT gt_control INTO DATA(ls_control) WHERE type = g_type AND fieldalv = 'HEAD'.
      CHECK ls_control-fieldname+0(6) <> 'AMOUNT'.
      CHECK ls_control-fieldname+0(5) <> 'MENGE'.

      ASSIGN COMPONENT ls_control-fieldname OF STRUCTURE gs_head TO FIELD-SYMBOL(<fs_value_h>).
      CHECK sy-subrc EQ 0.
      CHECK <fs_value_h> IS NOT INITIAL.

      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<fs_item>) .
        ASSIGN COMPONENT ls_control-fieldname OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fs_value_i>).
        CHECK sy-subrc EQ 0.
        IF <fs_value_i> IS INITIAL.
          <fs_value_i> = <fs_value_h>.
        ELSEIF ls_control-requi = 'X'.
          <fs_value_i> = <fs_value_h>.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD post.
    DATA rv_at TYPE REF TO zat_object.
    CREATE OBJECT rv_at."初始化对象

    rv_at->g_type = i_type.
    rv_at->g_budat = i_budat.
    rv_at->g_atno = i_atno.

    rv_at->get_data( )."读取数据
    return_error.

    rv_at->get_config( )."读取配置
    return_error.

    rv_at->lock( )."读取单号
    return_error.

    CASE rv_at->gs_head-status.
      WHEN 'S'.
        rv_at->add_msg( msgty = 'W' msgid = 'ZAT' msgno = '000' msgv1 = '已经过账，不需要处理' ).
      WHEN 'D' OR 'F'.
        rv_at->add_msg( msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = '已经作废，不能要处理' ).
      WHEN OTHERS.
        rv_at->go_step( ).
    ENDCASE.

    rv_at->unlock( ).

    et_return = rv_at->gt_return.
    e_status = rv_at->gs_head-status.

  ENDMETHOD.


  METHOD save_data.
    gs_head = VALUE #(  BASE gs_head
                                      aedat = sy-datum
                                      aetim =  sy-uzeit
                                      aenam = sy-uname
                                      ).
    MODIFY zatt_head FROM gs_head.
    MODIFY zatt_item FROM TABLE gt_item.
    MODIFY zatt_item_step FROM TABLE gt_item_step.
  ENDMETHOD.


  METHOD update_head_status.
    gs_head = VALUE #( BASE gs_head
                              status = i_status
                              aedat = sy-datum
                              aetim =  sy-uzeit
                              aenam = sy-uname
                              ).
    MODIFY zatt_head FROM @( CORRESPONDING #( gs_head ) ).
  ENDMETHOD.


  METHOD update_item_step.

    is_item_step = VALUE #( BASE is_item_step
                                                    uname = sy-uname
                                                    aedat = sy-datum
                                                    aetim = sy-uzeit
                                                    ).

    MODIFY zatt_item_step FROM is_item_step.

    IF is_item_step-status = 'E' OR is_item_step-status = 'F'.
      UPDATE zatt_head SET status = is_item_step-status
                              WHERE atno = is_item_step-atno.
    ELSEIF is_item_step-status = 'C'.
      binary_relation( EXPORTING is_item_step = is_item_step ).
    ENDIF.

    IF gt_message[] IS NOT INITIAL.
      LOOP AT gt_message ASSIGNING FIELD-SYMBOL(<fs_message>).
        <fs_message>-line = sy-tabix.
      ENDLOOP.
      MODIFY zatt_message FROM TABLE gt_message[].
    ENDIF.

  ENDMETHOD.


  METHOD cancel.

    DATA rv_at TYPE REF TO zat_object.
    CREATE OBJECT rv_at.

    rv_at->g_type = i_type.
    rv_at->g_budat = i_budat.

    rv_at->get_data( )."读取数据
    return_error.

    rv_at->lock( ).
    return_error.

    CASE rv_at->gs_head-status.
      WHEN 'A'.
        rv_at->update_head_status( 'D' ).
        COMMIT WORK AND WAIT.
      WHEN 'D'.
        rv_at->add_msg( msgty = 'W' msgid = 'ZAT' msgno = '000' msgv1 = '已经被作废' ).
      WHEN 'E' OR 'C' OR 'F'.
        rv_at->cancel_step( ).
    ENDCASE.

    rv_at->unlock( ).
    et_return = rv_at->gt_return.

  ENDMETHOD.


  METHOD cancel_single.
    DATA lt_return TYPE  bapiret2_t.
    CASE gs_item_step-step_type.
      WHEN 'PO_CRE'.
        lt_return = zat_cancel=>po_del( i_ebeln = gs_item_step-docnr ).
      WHEN 'STO_VL_CRE' OR 'SO_VL_CRE'.
        lt_return = zat_cancel=>vl_del( i_vbeln_vl = gs_item_step-docnr ).
      WHEN 'SO_CRE'.
        lt_return = zat_cancel=>so_del( i_vbeln_va = gs_item_step-docnr ).
      WHEN 'VL_GI' OR 'MB'.
        lt_return = zat_cancel=>mb_cancel( EXPORTING
          i_mblnr = gs_item_step-docnr
          i_mjahr = gs_item_step-cjahr
          i_budat = g_budat
        IMPORTING
          e_mblnr = gs_item_step-c_docnr
          e_mjahr = gs_item_step-c_cjahr
          ).
      WHEN 'BAPI'.
        CASE gs_item_step-objtype.
          WHEN 'BUS2012'.
            lt_return = zat_cancel=>po_del( i_ebeln = gs_item_step-docnr ).
          WHEN 'BUS2017'.
            lt_return = zat_cancel=>mb_cancel( EXPORTING
              i_mblnr = gs_item_step-docnr
              i_mjahr = gs_item_step-cjahr
              i_budat = g_budat
            IMPORTING
              e_mblnr = gs_item_step-c_docnr
              e_mjahr = gs_item_step-c_cjahr
              ).
          WHEN 'BUS2105'.
            lt_return = zat_cancel=>pr_del( i_banfn = gs_item_step-docnr ).
          WHEN 'VBAK'.
            lt_return = zat_cancel=>so_del( i_vbeln_va = gs_item_step-docnr ).
          WHEN 'LIKP'.
            lt_return = zat_cancel=>vl_del( i_vbeln_vl = gs_item_step-docnr ).
        ENDCASE.
    ENDCASE.

    LOOP AT lt_return INTO DATA(ls_return).
      add_msg( msgty = ls_return-type msgid = ls_return-id msgno = ls_return-number
                    msgv1 = ls_return-message_v1 msgv2 = ls_return-message_v2 msgv3 = ls_return-message_v3 msgv4 = ls_return-message_v4 ) .
    ENDLOOP.

    IF g_error = 'X'.
      ROLLBACK WORK.
      gs_item_step = VALUE #( status = 'F'
                                              msgtx = |凭证{ gs_item_step-docnr }冲销失败.| ).
      add_msg( msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = |{ gs_item_step-msgtx }|  ).
      update_item_step( CHANGING is_item_step = gs_item_step ).
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
    ELSE.
      gs_item_step-c_docnr = COND docnr( WHEN gs_item_step-c_docnr IS INITIAL THEN gs_item_step-docnr ).
      gs_item_step = VALUE #( status = 'D'
                                              msgtx = |凭证{ gs_item_step-docnr }冲销成功.| ).
      add_msg( msgty = 'S' msgid = 'ZAT' msgno = '000' msgv1 = |{ gs_item_step-msgtx }|  ).
      update_item_step( CHANGING is_item_step = gs_item_step ).
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
    ENDIF.
    MODIFY gt_item_step FROM gs_item_step.
    IF g_error = 'X'.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD cancel_step.
    DATA:lt_return TYPE bapiret2_t.
    CLEAR g_times.

    SORT gt_item_step BY step DESCENDING.

    SELECT SINGLE MAX( times ) FROM zatt_message
    WHERE atno = @gs_head-atno
    GROUP BY atno
    INTO @g_times.

    ADD 1 TO g_times.

    add_msg( EXPORTING msgty = 'S' msgid = 'ZAT' msgno = '000' msgv1 = |--自动交易{ gs_head-atno }正在冲销--| ).

    LOOP AT gt_item_step INTO gs_item_step.
      CASE gs_item_step-status.
        WHEN 'A' OR 'E'.        "初始/错误
          gs_item_step-status = 'D'.
          gs_item_step-msgtx = '未执行，取消成功'..
          update_item_step( CHANGING is_item_step = gs_item_step ) .
          CONTINUE.
        WHEN 'D' OR 'F'.        "已经完成
          CONTINUE.
        WHEN 'C'.        "继续执行冲销逻辑
      ENDCASE.
      cancel_single( ).
      IF g_error = 'X'.
        RETURN.
      ENDIF.
    ENDLOOP.

    IF g_error = ''.
      update_head_status( 'D' ).
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.


  METHOD get_data.
    SELECT SINGLE * FROM zatt_head
    WHERE atno = @g_atno
    AND type = @g_type
    INTO  @gs_head.

    SELECT * FROM zatt_item
    WHERE atno = @g_atno
    INTO TABLE @gt_item.

    SELECT * FROM zatt_item_step
    WHERE atno = @g_atno
    INTO TABLE @gt_item_step.

    IF gs_head IS INITIAL
    OR gt_item IS INITIAL
    OR gt_item_step IS INITIAL.
      add_msg( msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = '获取数据失败' ).
    ENDIF.
  ENDMETHOD.


  METHOD lock.
    CHECK gs_head-atno IS NOT INITIAL.
    CALL FUNCTION 'ENQUEUE_EZATT_HEAD'
      EXPORTING
        mode_zatt_head = 'E'
        mandt          = sy-mandt
        atno           = gs_head-atno
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      add_msg( msgty = sy-msgty
                          msgid = sy-msgid
                          msgno = sy-msgno
                          msgv1 = sy-msgv1
                          msgv2 = sy-msgv2
                          msgv3 = sy-msgv3
                          msgv4 = sy-msgv4
                          ).

    ENDIF.
  ENDMETHOD.


  METHOD progressbar_show.
    DATA: lv_msg TYPE string.
    IF i_msg IS INITIAL.
      lv_msg = |{ TEXT-t01 }........ { i_current }/{ i_total }|.
    ELSE.
      lv_msg = |{ i_msg }........ { i_current }/{ i_total }|..
    ENDIF.
    cl_progress_indicator=>progress_indicate(
    EXPORTING
      i_text               = lv_msg
      i_processed          = i_current
      i_total              = i_total
      i_output_immediately = abap_true ).

  ENDMETHOD.


  METHOD unlock.
    CHECK gs_head-atno IS NOT INITIAL.
    CALL FUNCTION 'DEQUEUE_EZATT_HEAD'
      EXPORTING
        mode_zatt_head = 'E'
        mandt          = sy-mandt
        atno           = gs_head-atno.
  ENDMETHOD.


  METHOD clear_buffer.
    CALL FUNCTION 'MARD_CLEAR_UPDATE_BUFFER' EXPORTING iv_clear_all_flag = 'X'.
  ENDMETHOD.
ENDCLASS.
