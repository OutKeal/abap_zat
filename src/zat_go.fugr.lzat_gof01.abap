*----------------------------------------------------------------------*
***INCLUDE LZAT_GOF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form frm_get_config
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*

FORM frm_get_config .

  SELECT SINGLE * FROM zatt_type
            WHERE type = @g_type
            INTO @gs_type.
  IF sy-subrc NE 0.
    PERFORM frm_add_msg USING 'E' 'ZAT' '001' '' '' '' ''."配置获取失败，请检查交易类型配置
    RETURN.
  ENDIF.

  SELECT  * FROM zatt_control
             WHERE type = @g_type
             INTO TABLE @gt_control.
  IF sy-subrc NE 0.
    PERFORM frm_add_msg USING 'E' 'ZAT' '001' '' '' '' ''."配置获取失败，请检查交易类型配置
    RETURN.
  ENDIF.

  SELECT  * FROM zatt_step
            WHERE type = @g_type
            INTO TABLE @gt_step.
  IF sy-subrc NE 0.
    PERFORM frm_add_msg USING 'E' 'ZAT' '001' '' '' '' ''."配置获取失败，请检查交易类型配置
    RETURN.
  ENDIF.

  SELECT  * FROM zatt_step_rule
            WHERE type = @g_type
            INTO TABLE @gt_step_rule.
  IF sy-subrc NE 0.
*    PERFORM frm_add_msg USING 'E' 'ZAT' '001' '' '' '' ''."配置获取失败，请检查交易类型配置
*    RETURN.
  ENDIF.

ENDFORM.

FORM frm_add_msg USING msgty msgid msgno msgv1 msgv2 msgv3 msgv4.

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
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_init_head
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_init_head .
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
ENDFORM.

FORM frm_init_item .

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

ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_next_msgnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- G_MSGNR
*&---------------------------------------------------------------------*
FORM get_next_atno CHANGING p_g_msgnr.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'ZATNO'
    IMPORTING
      number                  = p_g_msgnr
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
    PERFORM frm_add_msg USING 'E' 'ZAT' '000' '单号获取错误' '' '' ''.
  ELSE.
    COMMIT WORK AND WAIT.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_next_msgnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- G_MSGNR
*&---------------------------------------------------------------------*
FORM get_next_msgnr  CHANGING p_g_msgnr.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'ZATMSGNR'
    IMPORTING
      number                  = p_g_msgnr
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
    PERFORM frm_add_msg USING 'E' 'ZAT' '000' '日志编号获取错误' '' '' ''.
  ELSE.
    COMMIT WORK AND WAIT.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_step_go
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_step_go .
  CLEAR g_times.
  IF gs_head-status = 'A' OR gs_head-status = 'E' .
  ELSE.
    PERFORM frm_add_msg USING 'E' 'ZAT' '000' '无法执行' '' '' ''.
    RETURN.
  ENDIF.

  SORT gt_item_step BY step.
  SELECT SINGLE MAX( times ) FROM zatt_message
      WHERE atno = @gs_head-atno
      GROUP BY atno
      INTO @g_times.

  ADD 1 TO g_times.

  PERFORM frm_add_msg USING 'S' 'ZAT' '000' '--自动交易' gs_head-atno '正在执行--' ''.

  LOOP AT gt_item_step INTO gs_item_step
      WHERE status = 'A' OR status = 'E'.
    PERFORM frm_process_text USING gs_item_step 'DO'.
    CALL FUNCTION 'MARD_CLEAR_UPDATE_BUFFER' EXPORTING iv_clear_all_flag = 'X'.
    CASE gs_item_step-step_type.
      WHEN 'PO_CRE'.
        PERFORM frm_po_cre.
      WHEN 'STO_VL_CRE'.
        PERFORM frm_sto_vl_cre.
      WHEN 'VL_GI'.
        PERFORM frm_vl_gi.
      WHEN 'SO_CRE'.
        PERFORM frm_so_cre.
      WHEN 'SO_VL_CRE'.
        PERFORM frm_so_vl_cre.
      WHEN 'MB'.
        PERFORM frm_mb_post.
      WHEN 'BAPI'.
        PERFORM frm_bapi_do.
    ENDCASE.

    MODIFY gt_item_step FROM gs_item_step.
    IF g_error = 'X'.
      RETURN.
    ENDIF.
  ENDLOOP.
  IF g_error = ''.
    PERFORM frm_update_head_status USING gs_head 'C'.
    COMMIT WORK AND WAIT.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_init_item_step
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_init_item_step .


  LOOP AT gt_step INTO gs_step.
    MOVE-CORRESPONDING gs_step TO gs_item_step.
    gs_item_step = VALUE #( BASE gs_item_step
                                             status = 'A'
                                             atno = gs_head-atno ).

    APPEND gs_item_step TO gt_item_step.
    CLEAR gs_item_step.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_save_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_save_data .

  gs_head = VALUE #(  BASE gs_head
                                  aedat = sy-datum
                                  aetim =  sy-uzeit
                                  aenam = sy-uname
                                 ).
  MODIFY zatt_head FROM gs_head.
  MODIFY zatt_item FROM TABLE gt_item.
  MODIFY zatt_item_step FROM TABLE gt_item_step.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_move_value
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_RULE
*&      <-- <TO_F>
*&---------------------------------------------------------------------*


FORM frm_move_value USING ls_rule TYPE zatt_step_rule
                                        CHANGING fvalue.
  CASE  ls_rule-from_fieldalv.
    WHEN ' '.
      fvalue = ls_rule-default_value.
    WHEN 'HEAD'.
      ASSIGN COMPONENT ls_rule-from_fname OF STRUCTURE gs_head TO FIELD-SYMBOL(<from_f>).
      IF sy-subrc EQ 0.
        fvalue = <from_f>.
        PERFORM fm_zz_move_value USING ls_rule  CHANGING fvalue.
      ENDIF.
    WHEN 'ITEM'.
      ASSIGN COMPONENT ls_rule-from_fname OF STRUCTURE gs_item TO <from_f>.
      IF sy-subrc EQ 0.
        fvalue = <from_f>.
        PERFORM fm_zz_move_value USING ls_rule  CHANGING fvalue.
      ENDIF.
    WHEN 'LAST'.
      DATA:l_docnr TYPE docnr.
      PERFORM frm_get_last_docnr USING ls_rule-from_fname CHANGING l_docnr .
      fvalue = l_docnr.
  ENDCASE.
ENDFORM.

FORM frm_move_valuex USING yvalue
                                        CHANGING fvalue.

  IF cl_abap_typedescr=>describe_by_data( fvalue )->absolute_name = '\TYPE=BAPIUPDATE'.
    fvalue = 'X'.
  ELSE.
    fvalue = yvalue.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_UPDATE_ITEM_STEP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_update_item_step USING is_item_step TYPE zatt_item_step.
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
    PERFORM binary_relation USING is_item_step.
  ENDIF.

  IF gt_message[] IS NOT INITIAL.
    LOOP AT gt_message ASSIGNING FIELD-SYMBOL(<fs_message>).
      <fs_message>-line = sy-tabix.
    ENDLOOP.
    MODIFY zatt_message FROM TABLE gt_message[].
  ENDIF.
ENDFORM.

FORM binary_relation USING is_item_step TYPE zatt_item_step.
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
  CHECK ls_borident2 IS NOT INITIAL.

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

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_get_last_docnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- DOCNR
*&---------------------------------------------------------------------*
FORM frm_get_last_docnr USING step  CHANGING c_docnr.
  DATA:l_step TYPE zatd_step.
  IF step IS INITIAL.
    l_step = gs_item_step-step - 1.
  ELSE.
    l_step = step.
  ENDIF.
  READ TABLE gt_item_step INTO DATA(ls_item_step) WITH KEY
                                                                                              atno = gs_item_step-atno
                                                                                              step = l_step.
  IF sy-subrc EQ 0.
    c_docnr = ls_item_step-docnr.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_update_head_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_update_head_status USING is_head TYPE zatt_head status.

  is_head = VALUE #( BASE is_head
                                  status = status
                                  aedat = sy-datum
                                  aetim =  sy-uzeit
                                  aenam = sy-uname
                                ).

  MODIFY zatt_head FROM @( CORRESPONDING #( is_head ) ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_process_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_ITEM_STEP_STEP_TYPE
*&---------------------------------------------------------------------*
FORM frm_process_text  USING l_step TYPE zatt_item_step action.
  CHECK sy-batch = ''.
  DATA:ls_text TYPE char50.
  DATA:l_int TYPE int1.
  DATA(sum) = lines( gt_item_step ).
  CHECK sum <> 0.
  IF action = 'DO'.
    l_int = 100 * l_step-step / sum.
    ls_text = | { l_step-step_name }正在执行...({ l_step-step }/{ sum } ) |.
  ELSEIF action = 'RE'.
    l_int = 100 * ( sum - l_step-step ) / sum.
    ls_text = | { l_step-step_name }正在冲销...({ l_step-step }/{ sum } ) |.
  ENDIF.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = l_int
      text       = ls_text.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_move_head_to_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_move_head_to_item .


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

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_check_head_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_check_head_data .

  DATA rule TYPE TABLE OF zats_check_rule WITH HEADER LINE.
  DATA ret TYPE TABLE OF bapiret2 WITH HEADER LINE.
  CLEAR rule[].
  CLEAR ret[].

  rule[] = VALUE #( FOR ls_control IN gt_control
                              WHERE ( type = g_type AND fieldalv = 'HEAD' )
                               ( fieldname = ls_control-fieldname
                                 rollname = ls_control-rollname
                                 notnull = ls_control-requi
                                 ddtext = ls_control-coltext ) ).
  DELETE rule WHERE rollname IS INITIAL AND notnull IS INITIAL.

*  LOOP AT gt_control INTO gs_control WHERE type = g_type AND fieldalv = 'HEAD'.
*
*    IF gs_control-rollname IS NOT INITIAL OR gs_control-requi IS NOT INITIAL.
*      APPEND VALUE #( fieldname = gs_control-fieldname
*                                    rollname = gs_control-rollname
*                                    notnull = gs_control-requi
*                                    ddtext = gs_control-coltext
*                                    ) TO rule.
*    ENDIF.
*  ENDLOOP.

  CALL FUNCTION 'ZAT_CHECK_VALUE'
    EXPORTING
      line = gs_head
    TABLES
      rule = rule
      ret  = ret.

  LOOP AT ret.
    PERFORM frm_add_msg USING ret-type ret-id ret-number ret-message_v1
                    ret-message_v2 ret-message_v3 ret-message_v4.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_check_item_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_check_item_data .
  DATA rule TYPE TABLE OF zats_check_rule WITH HEADER LINE.
  DATA ret TYPE TABLE OF bapiret2 WITH HEADER LINE.
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

  LOOP AT ret.
    PERFORM frm_add_msg USING ret-type ret-id ret-number ret-message_v1
          ret-message_v2 ret-message_v3 ret-message_v4.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_EXORD_CHECK
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_HEAD
*&---------------------------------------------------------------------*
FORM frm_exord_check  .
  CHECK gs_head-exord IS NOT INITIAL.

  SELECT SINGLE * FROM zatt_head
              WHERE exord = @gs_head-exord
                  AND type = @g_type
                  AND status <> 'D'
                  INTO @DATA(l_head).

  IF sy-subrc EQ 0.

    IF l_head-status = 'A' OR l_head-status = 'E'.
      DATA lt_return TYPE bapiret2_tab.
      CALL FUNCTION 'ZAT_POST'
        EXPORTING
          iv_type   = l_head-type
          iv_atno   = l_head-atno
          iv_budat  = g_budat
        TABLES
          et_return = lt_return.
      LOOP AT lt_return INTO DATA(ls_return).
        PERFORM frm_add_msg
        USING ls_return-type
             ls_return-id
             ls_return-number
             ls_return-message_v1
             ls_return-message_v2
             ls_return-message_v3
             ls_return-message_v4.
      ENDLOOP.
      g_error = 'X'.
    ELSE.
      PERFORM frm_add_msg
      USING 'E'
            'ZAT'
            '000'
            '外部单号' gs_head-exord '已重复，请检查输入。单号为'
            l_head-atno .
    ENDIF.


  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_init_item_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_init_item_text .

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
      PERFORM frm_add_msg
      USING 'E'
            'ZAT'
            '000'
            '物料号' <fs_item>-matnr '不存在'
            '' .
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_lock USING atno TYPE zatd_atno.
  CALL FUNCTION 'ENQUEUE_EZATT_HEAD'
    EXPORTING
      mode_zatt_head = 'E'
      mandt          = sy-mandt
      atno           = atno
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    PERFORM frm_add_msg USING sy-msgty sy-msgid sy-msgno
                                                       sy-msgv1
                                                       sy-msgv2
                                                       sy-msgv3
                                                       sy-msgv4.
  ENDIF.
ENDFORM.

FORM frm_unlock USING atno TYPE zatd_atno.
  CALL FUNCTION 'DEQUEUE_EZATT_HEAD'
    EXPORTING
      mode_zatt_head = 'E'
      mandt          = sy-mandt
      atno           = atno.

ENDFORM.
