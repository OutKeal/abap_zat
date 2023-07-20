class ZAT_OBJECT definition
  public
  create public .

public section.

  methods CONSTRUCTOR .
  class-methods CREATE
    importing
      value(IS_HEAD) type ZATS_BAPI_HEAD
      value(IT_ITEM) type ZATTS_BAPI_ITEM
    exporting
      value(E_ATNO) type ZATT_HEAD-ATNO
      value(E_STATUS) type ZATT_HEAD-STATUS
      value(ET_RETURN) type BAPIRET2_T
    returning
      value(RV_AT) type ref to ZAT_OBJECT
    exceptions
      ERROR .
  class-methods POST .
  methods CLEAR .
protected section.

  data GS_HEAD type ZATT_HEAD .
  data GS_ITEM type ZATT_ITEM .
  data GS_CONTROL type ZATT_CONTROL .
  data GS_TYPE type ZATT_TYPE .
  data GS_STEP type ZATT_STEP .
  data GS_STEP_RULE type ZATT_STEP_RULE .
  data GS_ITEM_STEP type ZATT_ITEM_STEP .
  data GS_MESSAGE type ZATT_MESSAGE .
  data GS_RETURN type BAPIRET2 .
  data G_ERROR type CHAR1 .
  data G_TYPE type ZATD_TYPE .
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
*  gt_head      TYPE TABLE OF zatt_head,
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

  methods GET_CONFIG .
  methods CHECK_EXORD .
  methods CHECK_HEAD_DATA .
  methods CHECK_ITEM_DATA .
  methods INIT .
  methods INIT_DATA .
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
  methods GO_SINGLE .
ENDCLASS.



CLASS ZAT_OBJECT IMPLEMENTATION.


  METHOD ADD_MSG.
    IF msgty = 'E' OR msgty =  'A'.
      g_error = 'X'.
    ENDIF.
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


  method BINARY_RELATION.
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
  endmethod.


  METHOD CHECK_EXORD.
    CHECK gs_head-exord IS NOT INITIAL.

    SELECT SINGLE atno FROM zatt_head
    WHERE exord = @gs_head-exord
    AND type = @g_type
    AND status <> 'D'
    INTO @DATA(l_atno).

    IF sy-subrc EQ 0.
      DATA(L_TEXT) = |外部单号{ gs_head-exord }已重复，请检查输入。单号为{ l_atno }|.
      add_msg( EXPORTING msgty = 'E'  MSGID = 'ZAT' MSGNO = '000' MSGV1 = 'L_TEXT' ).
      return.
    ENDIF.
  ENDMETHOD.


  METHOD CHECK_HEAD_DATA.

    DATA rule TYPE TABLE OF zats_check_rule .
    DATA ret TYPE TABLE OF bapiret2 .
    CLEAR rule[].
    CLEAR ret[].

    rule[] = VALUE #( FOR ls_control IN gt_control
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
      add_msg( EXPORTING msgty = l_ret-type msgid = l_ret-id msgno = l_ret-number
     msgv1 = l_ret-message_v1
     msgv2 = l_ret-message_v2
     msgv3 = l_ret-message_v3
     msgv4 = l_ret-message_v4 ).

    ENDLOOP.
  ENDMETHOD.


  METHOD CHECK_ITEM_DATA.
    DATA rule TYPE TABLE OF zats_check_rule .
    DATA ret TYPE TABLE OF bapiret2 .
    CLEAR rule[].
    CLEAR ret[].

    LOOP AT gt_control INTO gs_control WHERE type = g_type AND fieldalv = 'HEAD'.
      IF gs_control-rollname IS NOT INITIAL OR gs_control-requi IS NOT INITIAL.
        APPEND VALUE #( fieldname = gs_control-fieldname
        rollname = gs_control-rollname
        notnull = gs_control-requi
        ddtext = gs_control-coltext
        ) TO rule.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'ZAT_CHECK_VALUE'
      TABLES
        tab  = gt_item[]
        rule = rule
        ret  = ret.

  LOOP AT ret INTO DATA(l_ret).
    add_msg( EXPORTING msgty = l_ret-TYPE msgid = l_ret-ID msgno = l_ret-NUMBER
      msgv1 = l_ret-message_v1
      msgv2 = l_ret-message_v2
      msgv3 = l_ret-message_v3
      msgv4 = l_ret-message_v4 ).

  ENDLOOP.

  ENDMETHOD.


  METHOD CLEAR.
    CLEAR: gt_item ,
    gt_control,
    gt_type ,
    gt_step,
    gt_step_rule,
    gt_item_step,
    gt_message,
    gt_return.

    CLEAR: gs_head,
    gs_item ,
    gs_control,
    gs_type ,
    gs_step,
    gs_step_rule,
    gs_item_step,
    gs_message,
    gs_return.

    CLEAR :g_budat,
    g_type,
    g_error,
    g_msgnr,
    g_times,
    g_mblnr,
    g_mjahr.
  ENDMETHOD.


  METHOD CONSTRUCTOR.
    CLEAR( ).

  ENDMETHOD.


  METHOD CREATE.
    CREATE OBJECT rv_at.

    rv_at->g_type = is_head-type.
    rv_at->g_budat = is_head-budat.
    MOVE-CORRESPONDING is_head TO rv_at->gs_head.
    MOVE-CORRESPONDING it_item[] TO rv_at->gt_item[].

    rv_at->get_config( ).
    IF rv_at->g_error = 'X'.
      et_return[] = rv_at->gt_return[].
      FREE rv_at.
      RETURN.
    ENDIF.

    rv_at->check_exord( ).
    IF rv_at->g_error = 'X'.
      et_return[] = rv_at->gt_return[].
      FREE rv_at.
      RETURN.
    ENDIF.

    rv_at->check_head_data( ).
    IF rv_at->g_error = 'X'.
      et_return[] = rv_at->gt_return[].
      FREE rv_at.
      RETURN.
    ENDIF.

    rv_at->check_item_data( ).
    IF rv_at->g_error = 'X'.
      et_return[] = rv_at->gt_return[].
      FREE rv_at.
      RETURN.
    ENDIF.

    rv_at->gs_head-atno = rv_at->get_next_atno( ).
    IF rv_at->g_error = 'X'.
      et_return[] = rv_at->gt_return[].
      FREE rv_at.
      RETURN.
    ENDIF.

    rv_at->init( ).
    rv_at->save_data( ).

    IF rv_at->gs_type-immed = 'X'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      rv_at->go_step( ).
    ENDIF.
    et_return[] = rv_at->gt_return[].
    e_atno = rv_at->gs_head-atno.
    e_status = rv_at->gs_head-status.

  ENDMETHOD.


  METHOD GET_CONFIG.


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


  METHOD GET_NEXT_ATNO.
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
    IF gs_head-status = 'A' OR gs_head-status = 'E' .
    ELSE.
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


  METHOD INIT.
    init_head( ).
    init_item( ).
    init_item_text( ).
    init_init_item_step( ).
    move_head_to_item( ).
  ENDMETHOD.


  method INIT_DATA.
  endmethod.


  METHOD INIT_HEAD.
    MOVE-CORRESPONDING gs_type TO gs_head.
    LOOP AT gt_control INTO gs_control WHERE type = g_type AND fieldalv = 'HEAD' AND zdefault <> ''.
      ASSIGN COMPONENT gs_control-fieldname OF STRUCTURE gs_head TO FIELD-SYMBOL(<fs_value>).
      IF sy-subrc EQ 0.
        IF <fs_value> IS INITIAL.
          <fs_value> = gs_control-zdefault.
        ENDIF.
      ENDIF.
    ENDLOOP.

    gs_head = VALUE #( BASE gs_head
    budat = g_budat
    status = 'A'
    erdat = sy-datum
    erzet =  sy-uzeit
    ernam = sy-uname
    ).
  ENDMETHOD.


  METHOD INIT_INIT_ITEM_STEP.
    LOOP AT gt_step INTO gs_step.
      MOVE-CORRESPONDING gs_step TO gs_item_step.
      gs_item_step = VALUE #( BASE gs_item_step
      status = 'A'
      atno = gs_head-atno ).

      APPEND gs_item_step TO gt_item_step.
      CLEAR gs_item_step.
    ENDLOOP.
  ENDMETHOD.


  METHOD INIT_ITEM.
    DATA:l_atnr TYPE mb_line_id.

    LOOP AT gt_control INTO gs_control WHERE type = g_type AND fieldalv = 'ITEM' AND zdefault <> ''.
      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<fs_item>).
        ASSIGN COMPONENT gs_control-fieldname OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fs_value>).
        IF sy-subrc EQ 0.
          IF <fs_value> IS INITIAL.
            <fs_value> = gs_control-zdefault.
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
      <fs_item>-atno = gs_head-atno.
      ADD c_nr TO l_atnr.
      <fs_item>-atnr = l_atnr.
      ADD <fs_item>-menge TO gs_head-menge.
      ADD <fs_item>-amount TO gs_head-amount.
    ENDLOOP.
  ENDMETHOD.


  METHOD INIT_ITEM_TEXT.

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
        IF <fs_item>-meins = ''.
          <fs_item>-meins = ls_mara-meins.
        ENDIF.
        IF <fs_item>-maktx = ''.
          <fs_item>-maktx = ls_mara-maktx.
        ENDIF.
      ELSE.
        add_msg( EXPORTING msgty = 'E' msgid = 'ZAT' msgno = '000' msgv1 = |物料号{ <fs_item>-matnr }不存在| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD MOVE_HEAD_TO_ITEM.

    LOOP AT gt_control INTO gs_control WHERE type = g_type AND fieldalv = 'HEAD'.

      CHECK gs_control-fieldname+0(6) <> 'AMOUNT'.
      CHECK gs_control-fieldname+0(5) <> 'MENGE'.

      ASSIGN COMPONENT gs_control-fieldname OF STRUCTURE gs_head TO FIELD-SYMBOL(<fs_value1>).
      CHECK sy-subrc EQ 0.
      CHECK <fs_value1> IS NOT INITIAL.

      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<fs_item>) .
        ASSIGN COMPONENT gs_control-fieldname OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fs_value2>).
        CHECK sy-subrc EQ 0.
        IF <fs_value2> IS INITIAL.
          <fs_value2> = <fs_value1>.
        ELSEIF gs_control-requi = 'X'.
          <fs_value2> = <fs_value1>.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD POST.





  ENDMETHOD.


  METHOD SAVE_DATA.
    gs_head = VALUE #(  BASE gs_head
    aedat = sy-datum
    aetim =  sy-uzeit
    aenam = sy-uname
    ).
    MODIFY zatt_head FROM gs_head.
    MODIFY zatt_item FROM TABLE gt_item.
    MODIFY zatt_item_step FROM TABLE gt_item_step.
  ENDMETHOD.


  METHOD UPDATE_HEAD_STATUS.
    gs_head = VALUE #( BASE gs_head
                              status = i_status
                              aedat = sy-datum
                              aetim =  sy-uzeit
                              aenam = sy-uname
                              ).

    MODIFY zatt_head FROM @( CORRESPONDING #( gs_head ) ).
  ENDMETHOD.


METHOD UPDATE_ITEM_STEP.

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
      <fs_message>-LINE = sy-tabix.
    ENDLOOP.
    MODIFY zatt_message FROM TABLE gt_message[].
  ENDIF.

ENDMETHOD.
ENDCLASS.
