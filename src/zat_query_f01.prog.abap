*&---------------------------------------------------------------------*
*& 包含               ZCCT_QUERY_F01
*&---------------------------------------------------------------------*

FORM frm_get_data.
  SELECT *
  INTO CORRESPONDING FIELDS OF TABLE @gt_head
  FROM zatt_head AS a
  WHERE a~type     IN @s_type
  AND a~werks      IN @s_werks
  AND a~lgort      IN @s_lgort
  AND a~umwrk      IN @s_umwrk
  AND a~umlgo      IN @s_umlgo
  AND a~budat         IN @s_budat
  AND a~exord    IN @s_exord
  AND a~atno          IN @s_atno
  AND a~erdat          IN @s_erdat
  AND a~status          IN @s_status.


  IF sy-subrc EQ 0.

    SELECT * FROM  zatt_item
    FOR ALL ENTRIES IN @gt_head
    WHERE atno = @gt_head-atno
    INTO CORRESPONDING FIELDS OF TABLE @gt_item.

    SELECT * FROM  zatt_item_step
    FOR ALL ENTRIES IN @gt_head
    WHERE atno = @gt_head-atno
    INTO CORRESPONDING FIELDS OF TABLE @gt_step
    .

    SELECT * FROM  zatt_message
    FOR ALL ENTRIES IN @gt_head
    WHERE atno = @gt_head-atno
    INTO CORRESPONDING FIELDS OF TABLE @gt_msg.

  ENDIF.
ENDFORM.

FORM frm_deal_data.
  LOOP AT gt_head ASSIGNING <gs_head>.
    PERFORM frm_set_icon USING <gs_head>-status
                                          CHANGING <gs_head>-icon
                                                              <gs_head>-text.
    PERFORM frm_lock CHANGING <gs_head>.
  ENDLOOP.

  LOOP AT gt_msg ASSIGNING FIELD-SYMBOL(<gs_msg>).
    <gs_msg>-icon = SWITCH icon_d( <gs_msg>-msgty
                                                          WHEN 'S' THEN icon_led_green
                                                          WHEN 'E' THEN icon_led_red
                                                          WHEN 'W' THEN icon_led_yellow
                                                           ).
  ENDLOOP.


  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<gs_item>).
    READ TABLE gt_head INTO DATA(ls_head) WITH KEY atno = <gs_item>-atno.
    IF sy-subrc EQ 0.
      <gs_item> = VALUE #( BASE <gs_item>
                                          icon = ls_head-icon
                                          text = ls_head-text
                                          ).
    ENDIF.
  ENDLOOP.

  LOOP AT gt_step ASSIGNING FIELD-SYMBOL(<gs_step>).
    PERFORM frm_set_icon USING <gs_step>-status
            CHANGING <gs_step>-icon
                                <gs_step>-text.
  ENDLOOP.

  SORT gt_head BY erdat DESCENDING erzet DESCENDING.

  gt_item_dis[] = gt_item[].
  gt_step_dis[] = gt_step[].
  gt_msg_dis[] = gt_msg[].

ENDFORM.

FORM frm_set_icon USING status CHANGING icon text.
  CASE status.
    WHEN 'A'."未处理
      icon = icon_yellow_light.
      text = '未处理'.
    WHEN 'B'."处理中


    WHEN 'C'."已处理
      icon = icon_green_light.
      text = '已处理'.
    WHEN 'D'."已作废
      icon = icon_delete.
      text = '已作废'.
    WHEN 'E'."处理错误
      icon = icon_red_light.
      text = '处理错误'.
    WHEN 'F'."作废错误
      icon = icon_message_error.
      text = '作废错误'.
  ENDCASE.
ENDFORM.

FORM frm_hotspot_click USING e_column_id
      e_row_id STRUCTURE  lvc_s_row.
  DATA:type TYPE char20.
  CASE e_column_id.
    WHEN 'ATNO'.
      READ TABLE gt_head INTO DATA(ls_head) INDEX e_row_id-index.
      IF sy-subrc EQ 0.
        PERFORM frm_call_gos USING ls_head-atno.
      ENDIF.
    WHEN 'DOCNR' OR 'C_DOCNR'.
      READ TABLE gt_step_dis INTO DATA(ls_step) INDEX e_row_id-index.
      IF sy-subrc EQ 0.
        type = ls_step-step_type.
        IF type = 'BAPI'.
          type =  ls_step-objtype.
        ENDIF.
        IF e_column_id = 'DOCNR'.
          CHECK ls_step-docnr IS NOT INITIAL.
          zat_go=>call_transaction( EXPORTING type = type docnr = ls_step-docnr cjahr = ls_step-cjahr ).
        ELSEIF e_column_id = 'C_DOCNR'.
          CHECK ls_step-c_docnr IS NOT INITIAL.
          zat_go=>call_transaction( EXPORTING type = type docnr = ls_step-c_docnr cjahr = ls_step-c_cjahr ).
        ENDIF.
      ENDIF.
  ENDCASE.

ENDFORM.


FORM f_display_detail.

  g_grid_up->get_selected_rows( IMPORTING et_index_rows = DATA(lt_index_rows) ).


  IF lt_index_rows[] IS  INITIAL.
    RETURN.
  ENDIF.
  CLEAR: gt_item_dis[].
  CLEAR: gt_msg_dis[].
  CLEAR: gt_step_dis[].
  LOOP AT lt_index_rows INTO DATA(ls_index_rows).
    READ TABLE gt_head ASSIGNING <gs_head> INDEX ls_index_rows-index .
    IF sy-subrc EQ  0.
      LOOP AT gt_item WHERE atno = <gs_head>-atno.
        APPEND gt_item TO gt_item_dis.
      ENDLOOP.


      LOOP AT gt_msg WHERE atno = <gs_head>-atno.
        APPEND gt_msg TO gt_msg_dis.
      ENDLOOP.

      LOOP AT gt_step WHERE atno = <gs_head>-atno.
        APPEND gt_step TO gt_step_dis.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

ENDFORM.


FORM frm_at_post.
  DATA:et_return TYPE TABLE OF bapiret2 WITH HEADER LINE.

  g_grid_up->get_selected_rows( IMPORTING et_index_rows = DATA(lt_index_rows) ).

  IF lt_index_rows[] IS INITIAL.
    MESSAGE '请选择抬头行' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CLEAR gt_message[].

  LOOP AT lt_index_rows INTO DATA(ls_index_rows).
    READ TABLE gt_head ASSIGNING <gs_head> INDEX ls_index_rows-index.
    CHECK sy-subrc EQ 0.
    IF NOT <gs_head>-status CA  'AE' .
      PERFORM frm_add_msg USING 'ZAT' 'W' '000' '交易编号' <gs_head>-atno '状态无法处理' ''.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'ZAT_POST'
      EXPORTING
        iv_type   = <gs_head>-type
        iv_atno   = <gs_head>-atno
        iv_budat  = <gs_head>-budat
      IMPORTING
        e_status  = <gs_head>-status
      TABLES
        et_return = et_return.

    <gs_head>-icon = SWITCH icon_d( <gs_head>-status
                                                           WHEN 'E' THEN icon_red_light
                                                           WHEN 'C' THEN icon_green_light
                                                           WHEN 'D' THEN icon_dummy
                                                           WHEN 'A' THEN icon_yellow_light
                                                            ).

    LOOP AT et_return.
      PERFORM frm_add_msg USING et_return-id
            et_return-type
            et_return-number
            et_return-message_v1
            et_return-message_v2
            et_return-message_v3
            et_return-message_v4.
    ENDLOOP.
    CLEAR et_return[].

  ENDLOOP.

  PERFORM frm_pop_msg.

ENDFORM.


FORM frm_at_cancel.

  DATA:ls_budat TYPE budat.
  DATA:ls_yrq TYPE char1.
  DATA:ls_ret TYPE char1.

  DATA: et_return	TYPE TABLE OF	bapiret2 WITH HEADER LINE.

  g_grid_up->get_selected_rows( IMPORTING et_index_rows = DATA(lt_index_rows) ).

  IF lt_index_rows[] IS INITIAL.
    MESSAGE '请选择抬头行' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM set_pop USING '确认冲销么?' CHANGING ls_budat ls_yrq ls_ret.

  CHECK ls_ret <> 'X'.
  IF ls_yrq = 'X'.
    ls_budat = <gs_head>-budat.
  ENDIF.
  CLEAR gt_message[].

  LOOP AT lt_index_rows INTO DATA(ls_index_rows).
    ASSIGN gt_head[ ls_index_rows-index ] TO <gs_head>.
    CHECK sy-subrc EQ 0.
    IF <gs_head>-status CA 'ACEF'.
      CALL FUNCTION 'ZAT_CANCEL' DESTINATION 'NONE'
        EXPORTING
          iv_atno   = <gs_head>-atno
          iv_type   = <gs_head>-type
          iv_budat  = ls_budat
        TABLES
          et_return = et_return.
      LOOP AT et_return WHERE type = 'E'.
        PERFORM frm_add_msg USING et_return-id
                                                           et_return-type
                                                           et_return-number
                                                           et_return-message_v1
                                                           et_return-message_v2
                                                           et_return-message_v3
                                                           et_return-message_v4.
      ENDLOOP.
      IF sy-subrc = 0.
        PERFORM frm_add_msg USING 'ZAT' 'E' '000' '交易编号' <gs_head>-atno '冲销错误' ''.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ELSE.
        <gs_head>-status = 'D'.
        PERFORM frm_set_icon USING <gs_head>-status
                                      CHANGING <gs_head>-icon
                                        <gs_head>-text.
        PERFORM frm_add_msg USING 'ZAT' 'S' '000' '交易编号' <gs_head>-atno '冲销成功' ''.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

    ELSE.
      PERFORM frm_add_msg USING 'ZAT' 'E' '000' '交易编号' <gs_head>-atno '状态无法冲销' ''.
    ENDIF.
  ENDLOOP.

  PERFORM frm_pop_msg.

ENDFORM.


FORM frm_add_msg USING msgid
      msgty
      msgno
      msgv1
      msgv2
      msgv3
      msgv4.

  CLEAR gt_msg.
  gt_message-msgid = msgid .
  gt_message-msgty = msgty .
  gt_message-msgno = msgno .
  gt_message-msgv1 = msgv1 .
  gt_message-msgv2 = msgv2 .
  gt_message-msgv3 = msgv3 .
  gt_message-msgv4 = msgv4 .
  APPEND gt_message.

ENDFORM.

FORM frm_pop_msg.
  IF gt_message[] IS NOT INITIAL.
    CALL FUNCTION 'C14Z_MESSAGES_SHOW_AS_POPUP'
      TABLES
        i_message_tab = gt_message[].
    CLEAR gt_message[].
  ENDIF.
ENDFORM.



FORM set_pop USING txt CHANGING ls_budat ls_yrq ls_ret.

  DATA:lt_flds TYPE TABLE OF sval.
  DATA:p_gv_ret_code TYPE char1.

  APPEND VALUE #( tabname = 'MKPF'
                                fieldname = 'BUDAT'
                                value = sy-datum
                                fieldtext = '冲销日期'
                           ) TO lt_flds.

  APPEND VALUE #( tabname = 'MKPF'
                                fieldname = 'FLS_RSTO'
                                value = 'X'
                                field_attr = '01'
                                fieldtext = '保持原有日期'
                                ) TO lt_flds.



  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = txt
    IMPORTING
      returncode      = p_gv_ret_code
    TABLES
      fields          = lt_flds
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.
  IF p_gv_ret_code = 'A'.
    MESSAGE '操作已取消' TYPE 'S'.
    ls_ret = 'X'.
  ENDIF.

  ls_budat = lt_flds[ fieldname = 'BUDAT' ]-value.
  ls_yrq = lt_flds[ fieldname = 'FLS_RSTO' ]-value.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CALL_GOS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_HEAD_ATNO
*&---------------------------------------------------------------------*
FORM frm_call_gos  USING    l_atno.
  DATA:manager TYPE REF TO cl_gos_manager.
  DATA:l_sgs_srvnam TYPE sgs_srvnam.
  DATA:obj TYPE borident.
  obj-objtype = 'ZAT'.
  obj-objkey = l_atno.
  FREE manager.
  CREATE OBJECT manager
    EXPORTING
      is_object = obj
    EXCEPTIONS
      OTHERS    = 1.
  l_sgs_srvnam = 'SRELATIONS'.
  CALL METHOD manager->start_service_direct
    EXPORTING
      ip_service       = l_sgs_srvnam
      is_object        = obj
    EXCEPTIONS
      no_object        = 1
      object_invalid   = 2
      execution_failed = 3
      OTHERS           = 4.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_call_trans
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_STEP_C_DOCNR
*&      --> LS_STEP_C_CJAHR
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form frm_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- <GS_HEAD>
*&---------------------------------------------------------------------*
FORM frm_lock CHANGING c_head TYPE zats_head.
  CHECK p_read IS INITIAL.
  CALL FUNCTION 'ENQUEUE_EZATT_HEAD'
    EXPORTING
      mode_zatt_head = 'E'
      mandt          = sy-mandt
      atno           = c_head-atno
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
    c_head-icon = icon_locked.
    c_head-text = '锁定'.
  ENDIF.


ENDFORM.
