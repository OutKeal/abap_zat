

DEFINE mapping.
  FIELD-SYMBOLS:
  <to_t>   TYPE table,
  <to_tx>  TYPE table,
  <to_s>   TYPE any,
  <to_sx>  TYPE any,
  <to_f>   TYPE any,
  <to_fx>  TYPE any.

  DATA:l_fieldname TYPE char40.

  SORT gt_step_rule BY type step rule_type to_tabname.

  LOOP AT gt_step_rule INTO gs_step_rule
  WHERE step = gs_item_step-step
  GROUP BY ( type = gs_step_rule-type
  step = gs_step_rule-step
  rule_type = gs_step_rule-rule_type
  to_tabname = gs_step_rule-to_tabname
  ) INTO DATA(lt_rule).

    CASE lt_rule-rule_type.
    WHEN 'G'.
      LOOP AT GROUP lt_rule INTO DATA(ls_rule).
        ASSIGN (ls_rule-to_fieldname) TO <to_f>.
        CHECK sy-subrc EQ 0.
        PERFORM frm_move_value USING ls_rule CHANGING <to_f>.
      ENDLOOP.
    WHEN 'H'.
      l_fieldname = 'LS_' && lt_rule-to_tabname.
      ASSIGN (l_fieldname) TO <to_s>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LS_' && lt_rule-to_tabname && 'X'.
      ASSIGN (l_fieldname) TO <to_sx>.
      LOOP AT GROUP lt_rule INTO ls_rule.
        ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_s> TO <to_f>.
        CHECK sy-subrc EQ 0.
        PERFORM frm_move_value USING ls_rule CHANGING <to_f>.
        ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_sx> TO <to_fx>.
        IF sy-subrc EQ 0.
          PERFORM frm_move_valuex USING <to_f> CHANGING <to_fx>.
        ENDIF.
      ENDLOOP.
    WHEN 'I'.
      l_fieldname = 'LT_' && lt_rule-to_tabname && '[]'.
      ASSIGN (l_fieldname) TO <to_t>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LT_' && lt_rule-to_tabname.
      ASSIGN (l_fieldname) TO <to_s>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LT_' && lt_rule-to_tabname && 'X[]'.
      ASSIGN (l_fieldname) TO <to_tx>.
      l_fieldname = 'LT_' && lt_rule-to_tabname && 'X'.
      ASSIGN (l_fieldname) TO <to_sx>.

      LOOP AT gt_item INTO gs_item.
        LOOP AT GROUP lt_rule INTO ls_rule.
          ASSIGN COMPONENT ls_rule-to_fieldname  OF STRUCTURE <to_s> TO <to_f>.
          CHECK sy-subrc EQ 0.
          PERFORM frm_move_value USING ls_rule CHANGING <to_f>.
          ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_sx> TO <to_fx>.
          IF sy-subrc EQ 0.
            PERFORM frm_move_valuex USING <to_f> CHANGING <to_fx>.
          ENDIF.
        ENDLOOP.
        IF <to_s> IS ASSIGNED AND <to_t> IS ASSIGNED.
          APPEND <to_s> TO <to_t>.
          CLEAR  <to_s>.
        ENDIF.
        IF <to_sx> IS ASSIGNED AND <to_tx> IS ASSIGNED.
          APPEND <to_sx> TO <to_tx>.
          CLEAR <to_sx>.
        ENDIF.
      ENDLOOP.
    WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
END-OF-DEFINITION.


*&---------------------------------------------------------------------*
*& Form frm_sto_cre
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_po_cre .
  DATA:ls_pohead  LIKE  bapimepoheader,
       ls_poheadx LIKE  bapimepoheaderx,
       lt_return  TYPE TABLE OF  bapiret2            WITH HEADER LINE,
       lt_poitem  TYPE TABLE OF  bapimepoitem        WITH HEADER LINE,
       lt_poitemx TYPE TABLE OF  bapimepoitemx       WITH HEADER LINE,
       lt_poline  TYPE TABLE OF  bapimeposchedule    WITH HEADER LINE,
       lt_polinex TYPE TABLE OF  bapimeposchedulx    WITH HEADER LINE,
       lt_pocond  TYPE TABLE OF  bapimepocond        WITH HEADER LINE,
       lt_pocondx TYPE TABLE OF  bapimepocondx       WITH HEADER LINE.

  DATA:e_ebeln TYPE ebeln.

  mapping.

  IF ls_pohead-doc_type = 'ZT04' OR ls_pohead-doc_type = 'ZRT4'.
    LOOP AT gt_item INTO gs_item WHERE amount = ''.
      READ TABLE lt_poitemx ASSIGNING FIELD-SYMBOL(<fs_x>) WITH KEY po_item = gs_item-atnr.
      IF sy-subrc EQ 0.
        <fs_x>-ir_ind = 'X'.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF ls_pohead IS INITIAL OR lt_poitem[] IS INITIAL .
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' '采购订单处理失败，请检查配置' '' '' ''.
    RETURN.
  ENDIF.

  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = ls_pohead
      poheaderx        = ls_poheadx
    IMPORTING
      exppurchaseorder = e_ebeln
    TABLES
      return           = lt_return
      poitem           = lt_poitem
      poitemx          = lt_poitemx
      poschedule       = lt_poline
      poschedulex      = lt_polinex
      pocond           = lt_pocond
      pocondx          = lt_pocondx.

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
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 采购订单{ e_ebeln  }创建失败|.
    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 采购订单{ e_ebeln  }创建成功|.
    gs_item_step-docnr = e_ebeln.

    PERFORM frm_add_msg USING 'S' 'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_sto_vl_cre
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_sto_vl_cre .
  DATA:ship_point   TYPE vstel,
       lt_stovlitem TYPE TABLE OF bapidlvreftosto WITH HEADER LINE.

  DATA:et_created_items TYPE TABLE OF bapidlvitemcreated WITH HEADER LINE.
  DATA:et_return TYPE TABLE OF bapiret2 WITH HEADER LINE  .
  DATA:e_vbeln TYPE vbeln_vl.
  DATA:e_num TYPE vbnum.

  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
  mapping.

  IF lt_stovlitem[] IS INITIAL.
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '交货单处理失败，请检查配置' '' '' ''.
    RETURN.
  ENDIF.
  CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_STO'
    EXPORTING
      ship_point        = ship_point
    IMPORTING
      delivery          = e_vbeln
      num_deliveries    = e_num
    TABLES
      stock_trans_items = lt_stovlitem[]
      created_items     = et_created_items[]
      return            = lt_return[].
  IF e_num > 1.
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '交货单已拆单，请检查' '' '' ''.
    ROLLBACK WORK.
  ENDIF.
  IF lines( et_created_items ) <> lines( lt_stovlitem ).
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '交货单未完全创建,请检查' '' '' ''.
    ROLLBACK WORK.
  ENDIF.

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

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 交货单{ e_vbeln }创建失败|.
*    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 交货单{ e_vbeln }创建成功|.
    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_sto_vl_gi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_vl_gi .
  DATA:ls_vlhead    TYPE vbkok,
       vbeln        TYPE vbeln_vl,
       lt_vlitem    TYPE TABLE OF bapiobdlvitemcon WITH HEADER LINE,
       lt_vlcontrol TYPE TABLE OF bapiobdlvitemctrlcon WITH HEADER LINE.
  DATA:lt_prot TYPE TABLE OF prott WITH HEADER LINE.
  CLEAR: g_mblnr,g_mjahr.
  mapping.
*--发货过账
  CALL FUNCTION 'WS_DELIVERY_UPDATE'
    EXPORTING
      vbkok_wa      = ls_vlhead
      delivery      = vbeln
    TABLES
      prot          = lt_prot
    EXCEPTIONS
      error_message = 1
      OTHERS        = 2.

  IF g_mblnr IS INITIAL.
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '物料凭证生成失败' '' '' ''.
  ENDIF.
  LOOP AT lt_prot WHERE msgty = 'E' OR msgty = 'A'.
    PERFORM frm_add_msg USING
          lt_prot-msgty
          lt_prot-msgid
          lt_prot-msgno
          lt_prot-msgv1
          lt_prot-msgv2
          lt_prot-msgv3
          lt_prot-msgv4.
  ENDLOOP.
  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 交货单{ vbeln }过账失败 | .
*    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 交货单{ vbeln }过账成功,物料凭证{ g_mblnr }.|.
    gs_item_step-docnr = g_mblnr .
    gs_item_step-cjahr = g_mjahr .

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_so_cre
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_so_cre .
  DATA: ls_sohead  TYPE bapisdhd1,
        ls_soheadx TYPE bapisdhd1x,
        lt_partner TYPE TABLE OF  bapiparnr WITH HEADER LINE,
        lt_return  TYPE TABLE OF bapiret2 WITH HEADER LINE,
        lt_soitem  TYPE TABLE OF bapisditm WITH HEADER LINE,
        lt_soitemx TYPE TABLE OF bapisditmx WITH HEADER LINE,
        lt_soline  TYPE TABLE OF   bapischdl WITH HEADER LINE,
        lt_solinex TYPE TABLE OF bapischdlx WITH HEADER LINE,
        lt_cond    TYPE STANDARD TABLE OF bapicond WITH HEADER LINE,
        lt_condx   TYPE STANDARD TABLE OF bapicondx WITH HEADER LINE.

  DATA:e_vbeln TYPE vbeln.
  CALL FUNCTION 'MARD_CLEAR_UPDATE_BUFFER' EXPORTING iv_clear_all_flag = 'X'.
  mapping.

  PERFORM frm_set_partner TABLES lt_partner
  USING gs_head-kunnr
        ls_sohead.

  CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
    EXPORTING
      sales_header_in      = ls_sohead
      sales_header_inx     = ls_soheadx
    IMPORTING
      salesdocument_ex     = e_vbeln
    TABLES
      return               = lt_return[]
      sales_items_in       = lt_soitem[]
      sales_items_inx      = lt_soitemx[]
      sales_partners       = lt_partner[]
      sales_conditions_in  = lt_cond[]
      sales_conditions_inx = lt_condx[]
      sales_schedules_in   = lt_soline[]
      sales_schedules_inx  = lt_solinex[].

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

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 销售订单{ e_vbeln }创建失败|.
*    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'E'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 销售订单{ e_vbeln }创建成功|.
    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_so_vl_cre
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_so_vl_cre .
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
  DATA:lt_sovlitem TYPE TABLE OF bapidlvreftosalesorder WITH HEADER LINE.
  DATA:et_created_items TYPE TABLE OF bapidlvitemcreated WITH HEADER LINE.
  DATA:et_return TYPE TABLE OF bapiret2 WITH HEADER LINE  .
  DATA:ship_point TYPE vstel.
  DATA:e_vbeln TYPE vbeln_vl.
  DATA:e_num TYPE vbnum.

  mapping.

  IF lt_sovlitem[] IS INITIAL.
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' '交货单处理失败，请检查配置' '' '' ''.
    RETURN.
  ENDIF.
  CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
    EXPORTING
      ship_point        = ship_point
    IMPORTING
      delivery          = e_vbeln
      num_deliveries    = e_num
    TABLES
      sales_order_items = lt_sovlitem
      created_items     = et_created_items
      return            = lt_return[].

  IF e_num > 1.
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '交货单已拆单，请检查' '' '' ''.
    ROLLBACK WORK.
  ENDIF.

  IF lines( et_created_items ) <> lines( lt_sovlitem ).
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' '交货单未完全创建,请检查' '' '' ''.
    ROLLBACK WORK.
  ENDIF.


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

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 交货单{ e_vbeln }创建失败|.
*    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 交货单{ e_vbeln }创建成功|.
    gs_item_step-docnr = e_vbeln.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_so_vl_gi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_so_vl_gi .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_mb_post
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_mb_post .
  DATA:gm_code   TYPE bapi2017_gm_code,
       ls_mbhead TYPE bapi2017_gm_head_01,
       lt_mbitem TYPE TABLE OF bapi2017_gm_item_create WITH HEADER LINE.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
  DATA:e_mblnr TYPE mblnr.
  DATA:e_mjahr TYPE mjahr.
  mapping.

  CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
    EXPORTING
      goodsmvt_header  = ls_mbhead
      goodsmvt_code    = gm_code
    IMPORTING
      materialdocument = e_mblnr
      matdocumentyear  = e_mjahr
    TABLES
      goodsmvt_item    = lt_mbitem
      return           = lt_return.
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

  IF g_error = 'X'.
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = | 物料凭证{ e_mblnr } 创建失败|.
*    gs_item_step-docnr = e_vbeln.
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 物料凭证{ e_mblnr } 创建成功|.
    gs_item_step-docnr = e_mblnr.
    gs_item_step-cjahr = e_mjahr.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.

ENDFORM.

FORM frm_bapi_do.
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
    PERFORM frm_add_msg USING 'E'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
    RETURN.
  ENDIF.

  LOOP AT ret-return INTO DATA(ls_return) .
    PERFORM frm_add_msg USING
          ls_return-type
          ls_return-id
          ls_return-number
          ls_return-message_v1
          ls_return-message_v2
          ls_return-message_v3
          ls_return-message_v4.
  ENDLOOP.

  IF g_error = 'X'."BAPI返回失败
    ROLLBACK WORK.
    gs_item_step-status = 'E'.
    gs_item_step-msgtx = |凭证创建失败|.
*    gs_item_step-docnr = e_vbeln.
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ELSE.
    gs_item_step-status = 'C'.
    gs_item_step-msgtx = | 凭证{ ret-docnr } 创建成功|.
    gs_item_step-docnr = ret-docnr.
    gs_item_step-cjahr = ret-cjahr.
    gs_item_step-objtype = ret-objtype.

    PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_item_step-msgtx '' '' ''.
    PERFORM frm_update_item_step USING gs_item_step .
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_set_partner
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_PARTNER
*&      --> GS_HEAD_KUNNR
*&      --> LS_SOHEAD
*&---------------------------------------------------------------------*
FORM frm_set_partner  TABLES   ct_partner STRUCTURE bapiparnr
USING    i_kunnr
      i_sohead TYPE bapisdhd1.
  CLEAR ct_partner[].
  CHECK i_kunnr IS NOT INITIAL.

  SELECT * FROM knvp
  WHERE kunnr = @i_kunnr
  AND vkorg = @i_sohead-sales_org
  AND vtweg = @i_sohead-distr_chan
  AND spart = @i_sohead-division
  INTO TABLE @DATA(lt_knvp).

  LOOP AT lt_knvp INTO DATA(ls_knvp).
    APPEND VALUE #(
    partn_role = ls_knvp-parvw
    partn_numb = ls_knvp-kunn2
    ) TO ct_partner.
  ENDLOOP.
ENDFORM.
