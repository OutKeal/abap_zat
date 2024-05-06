*----------------------------------------------------------------------*
***INCLUDE LZAT_GOF03.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form frm_step_cancel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_step_cancel .
  CLEAR g_times.

  SORT gt_item_step BY step DESCENDING.

  SELECT SINGLE MAX( times ) FROM zatt_message
  WHERE atno = @gs_head-atno
  GROUP BY atno
  INTO @g_times.

  ADD 1 TO g_times.

  PERFORM frm_add_msg USING 'S' 'ZAT' '000' '--自动交易' gs_head-atno '正在冲销--' ''.

  LOOP AT gt_item_step INTO gs_item_step.

    PERFORM frm_process_text USING gs_item_step 'RE'.

    CASE gs_item_step-status.

      WHEN 'A' OR 'E'.        "初始/错误
        gs_item_step-status = 'D'.
        gs_item_step-msgtx = '未执行，取消成功'.
*        PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
        PERFORM frm_update_item_step USING gs_item_step .
        CONTINUE.
      WHEN 'D' .        "已经完成
        CONTINUE.
      WHEN 'C' OR 'F'.        "继续执行冲销逻辑
    ENDCASE.

    CASE gs_item_step-step_type.
      WHEN 'PO_CRE'.
        PERFORM frm_po_del.
      WHEN 'STO_VL_CRE'.
        PERFORM frm_vl_del.
      WHEN 'VL_GI'.
        PERFORM frm_vl_gi_re.
      WHEN 'SO_CRE'.
        PERFORM frm_so_del.
      WHEN 'SO_VL_CRE'.
        PERFORM frm_vl_del.
      WHEN 'MB'.
        PERFORM frm_mb_cancel.
      WHEN 'BAPI'.
        PERFORM frm_bapi_cancel.
    ENDCASE.

    MODIFY gt_item_step FROM gs_item_step.
    IF g_error = 'X'.
      RETURN.
    ENDIF.
  ENDLOOP.
  IF g_error = ''.
    PERFORM frm_update_head_status USING gs_head 'D'.
    COMMIT WORK AND WAIT.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_po_del
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_po_del .
  DATA:l_ebeln TYPE ebeln.
  DATA:ls_head   TYPE bapimepoheader,
       ls_headx  TYPE bapimepoheaderx,
       lt_return TYPE TABLE OF  bapiret2            WITH HEADER LINE.

  l_ebeln = gs_item_step-docnr.
  ls_head = VALUE #( po_number = l_ebeln
                                  delete_ind = 'X' ).
  ls_headx = VALUE #( po_number = 'X'
                                   delete_ind = 'X' ).

  CALL FUNCTION 'BAPI_PO_CHANGE'
    EXPORTING
      purchaseorder = l_ebeln
      poheader      = ls_head
      poheaderx     = ls_headx
    TABLES
      return        = lt_return.

  LOOP AT lt_return WHERE type = 'A' OR type = 'E'.
    PERFORM frm_add_msg USING
          lt_return-type
          lt_return-id
          lt_return-number
          lt_return-message_v1
          lt_return-message_v2
          lt_return-message_v3
          lt_return-message_v4.
  ENDLOOP.

  IF g_error EQ 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'F'.
    gs_item_step-msgtx = | 采购订单{ l_ebeln  }删除失败|.

    PERFORM frm_add_msg USING 'E' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ELSE.
    gs_item_step-status = 'D'.
    gs_item_step-msgtx = | 采购订单{ l_ebeln  }删除成功|.
    gs_item_step-c_docnr = l_ebeln.

    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_vl_del
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_vl_del .
  DATA:vbeln TYPE vbeln.
  DATA: ls_header_data    LIKE bapiobdlvhdrchg,
        ls_header_control LIKE bapiobdlvhdrctrlchg,
        lt_return         LIKE bapiret2 OCCURS 0 WITH HEADER LINE.

  vbeln = gs_item_step-docnr.
  ls_header_data-deliv_numb = vbeln.
  ls_header_control = VALUE #( deliv_numb = vbeln
                                                  dlv_del = 'X'
                                                  ).

  CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
    EXPORTING
      header_data    = ls_header_data
      header_control = ls_header_control
      delivery       = vbeln
    TABLES
      return         = lt_return[].

  LOOP AT lt_return.
    PERFORM frm_add_msg USING lt_return-type
          lt_return-id
          lt_return-number
          lt_return-message_v1
          lt_return-message_v2
          lt_return-message_v3
          lt_return-message_v4.
  ENDLOOP.

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'F'.
    gs_item_step-msgtx = | 交货单{ vbeln }删除失败 | .
*    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'E'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'D'.
    gs_item_step-msgtx = | 交货单{ vbeln }删除成功.|.
    gs_item_step-c_docnr = vbeln .

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_mb_cancel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_mb_cancel .
  DATA:mblnr TYPE mblnr.
  DATA:mjahr TYPE mjahr.
  DATA:ret TYPE bapi2017_gm_head_ret.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.

  mblnr = gs_item_step-docnr.
  mjahr = gs_item_step-cjahr.

  CALL FUNCTION 'BAPI_GOODSMVT_CANCEL' DESTINATION 'NONE'
    EXPORTING
      materialdocument    = mblnr
      matdocumentyear     = mjahr
      goodsmvt_pstng_date = g_budat
    IMPORTING
      goodsmvt_headret    = ret
    TABLES
      return              = lt_return[].

  g_mblnr = ret-mat_doc.
  g_mjahr = ret-doc_year.


  LOOP AT lt_return.
    PERFORM frm_add_msg USING lt_return-type
          lt_return-id
          lt_return-number
          lt_return-message_v1
          lt_return-message_v2
          lt_return-message_v3
          lt_return-message_v4.
  ENDLOOP.

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'F'.
    gs_item_step-msgtx = | 物料凭证{ mblnr }冲销失败 | .

    PERFORM frm_add_msg USING 'E'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'D'.
    gs_item_step-msgtx = | 物料凭证{ mblnr }冲销成功.|.
    gs_item_step-c_docnr = g_mblnr .
    gs_item_step-c_cjahr = g_mjahr .

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE' EXPORTING wait = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_so_del
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_so_del .

  DATA:vbeln TYPE vbeln.
  DATA:order_header_inx LIKE  bapisdh1x.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.

  vbeln = gs_item_step-docnr.
  order_header_inx-updateflag = 'D'.

  CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
    EXPORTING
      salesdocument    = vbeln
      order_header_inx = order_header_inx
    TABLES
      return           = lt_return.

  LOOP AT lt_return.
    PERFORM frm_add_msg USING lt_return-type
          lt_return-id
          lt_return-number
          lt_return-message_v1
          lt_return-message_v2
          lt_return-message_v3
          lt_return-message_v4.
  ENDLOOP.

  IF g_error EQ 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'F'.
    gs_item_step-msgtx = | 销售订单{ vbeln  }删除失败|.

    PERFORM frm_add_msg USING 'E' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ELSE.
    gs_item_step-status = 'D'.
    gs_item_step-msgtx = | 销售订单{ vbeln }删除成功|.
    gs_item_step-c_docnr = vbeln.

    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form frm_vl_gi_re
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_vl_gi_re .
  DATA:lv_vbtyp  LIKE likp-vbtyp .
  DATA:vbeln TYPE vbeln.
  DATA:lt_return TYPE TABLE OF mesg WITH HEADER LINE.

  SELECT SINGLE le_vbeln
    FROM mkpf
    WHERE mblnr = @gs_item_step-docnr
    AND mjahr = @gs_item_step-cjahr
    INTO @vbeln.

  IF sy-subrc NE 0.
    PERFORM frm_add_msg USING 'S' 'ZAT' '000' '交货单号确认失败' '' '' ''.
  ENDIF.

  SELECT SINGLE vbtyp                                                                                                    "SD 凭证类别
      FROM likp
      INTO lv_vbtyp
      WHERE vbeln  = vbeln .

  CALL FUNCTION 'WS_REVERSE_GOODS_ISSUE'
    EXPORTING
      i_vbeln                   = vbeln
      i_budat                   = g_budat
      i_count                   = '001'
      i_mblnr                   = ''
      i_tcode                   = 'VL09'
      i_vbtyp                   = lv_vbtyp                             "SD 凭证类别
    TABLES
      t_mesg                    = lt_return
    EXCEPTIONS
      error_reverse_goods_issue = 1
      error_message             = 2                 "v_n_1449556
      OTHERS                    = 3.

  IF sy-subrc EQ 0.
  ELSE.
    g_error = 'X'.
    PERFORM frm_add_msg USING sy-msgty sy-msgid sy-msgno sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF g_error EQ 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'F'.
    gs_item_step-msgtx = | 交货单{ vbeln  }冲销失败|.

    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'D'.
    gs_item_step-msgtx = | 交货单{ vbeln }冲销成功|.
    gs_item_step-c_docnr = g_mblnr.
    gs_item_step-c_cjahr = g_mjahr.

    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.

ENDFORM.

FORM frm_bapi_cancel.
  CASE gs_item_step-objtype.
    WHEN 'BUS2017'.
      SELECT SINGLE blart
        FROM mkpf
        WHERE mblnr = @gs_item_step-docnr
        AND mjahr = @gs_item_step-cjahr
        INTO @DATA(blart).
      IF blart = 'WL'.
        PERFORM frm_vl_gi_re.
      ELSE.
        PERFORM frm_mb_cancel.
      ENDIF.
    WHEN 'BUS2012'.
      PERFORM frm_po_del.
    WHEN 'LIKP'.
      PERFORM frm_vl_del.
    WHEN 'VBAK'.
      PERFORM frm_so_del.
  ENDCASE.


ENDFORM.
