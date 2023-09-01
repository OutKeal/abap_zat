class ZAT_CANCEL definition
  public
  final
  create public .

public section.

  class-methods PO_DEL
    importing
      !I_EBELN type EBELN
    returning
      value(R_RETURN) type BAPIRET2_T .
  class-methods VL_DEL
    importing
      value(I_VBELN_VL) type VBELN_VL
    returning
      value(R_RETURN) type BAPIRET2_T .
  class-methods MB_CANCEL
    importing
      value(I_MBLNR) type MBLNR
      value(I_MJAHR) type MJAHR
      value(I_BUDAT) type BUDAT
    exporting
      !E_MBLNR type MBLNR
      !E_MJAHR type MJAHR
    returning
      value(R_RETURN) type BAPIRET2_T .
  class-methods SO_DEL
    importing
      value(I_VBELN_VA) type VBELN_VA
    returning
      value(R_RETURN) type BAPIRET2_T .
  class-methods PR_DEL
    importing
      value(I_BANFN) type BANFN
    returning
      value(R_RETURN) type BAPIRET2_T .
protected section.
private section.
ENDCLASS.



CLASS ZAT_CANCEL IMPLEMENTATION.


  METHOD mb_cancel.
    DATA:lt_mseg TYPE TABLE OF mesg .
    SELECT
      SINGLE blart,le_vbeln INTO @DATA(l_mkpf)
      FROM mkpf
      WHERE mblnr = @i_mblnr
      AND mjahr = @i_mjahr.
    IF sy-subrc NE 0.
      APPEND VALUE #( type = 'E'
                                    id = 'ZAT'
                                    number = '000'
                                    message_v1 = '凭证号有误'
                                  ) TO r_return.
      RETURN.
    ELSEIF l_mkpf-blart = 'WL'.
      SELECT SINGLE vbtyp                                                                                                    "SD 凭证类别
              FROM likp
              INTO @DATA(l_vbtyp)
              WHERE vbeln  = @l_mkpf-le_vbeln .
      CALL FUNCTION 'WS_REVERSE_GOODS_ISSUE'
        EXPORTING
          i_vbeln                   = l_mkpf-le_vbeln
          i_budat                   = i_budat
          i_count                   = '001'
          i_mblnr                   = ''
          i_tcode                   = 'VL09'
          i_vbtyp                   = l_vbtyp                             "SD 凭证类别
        TABLES
          t_mesg                    = lt_mseg
        EXCEPTIONS
          error_reverse_goods_issue = 1
          error_message             = 2                 "v_n_1449556
          OTHERS                    = 3.
      IF sy-subrc NE 0.
        APPEND VALUE #( type = sy-msgty
                                      id = sy-msgid
                                      number = sy-msgno
                                      message_v1 = sy-msgv1
                                      message_v2 = sy-msgv2
                                      message_v3 = sy-msgv3
                                      message_v4 = sy-msgv4
                                      ) TO r_return.
      ELSE.
        ASSIGN ('(SAPLZAT_GO)G_MBLNR') TO FIELD-SYMBOL(<g_mblnr>).
        ASSIGN ('(SAPLZAT_GO)G_MJAHR') TO FIELD-SYMBOL(<g_mjahr>).
        IF <g_mblnr> IS ASSIGNED AND <g_mjahr> IS ASSIGNED.
          e_mblnr = <g_mblnr>.
          e_mjahr = <g_mjahr>.
        ENDIF.
      ENDIF.
    ELSE.
      DATA:ret TYPE bapi2017_gm_head_ret.
      CALL FUNCTION 'BAPI_GOODSMVT_CANCEL' DESTINATION 'NONE'
        EXPORTING
          materialdocument    = i_mblnr
          matdocumentyear     = i_mjahr
          goodsmvt_pstng_date = i_budat
        IMPORTING
          goodsmvt_headret    = ret
        TABLES
          return              = r_return[].
      e_mblnr = ret-mat_doc.
      e_mjahr = ret-doc_year.

    ENDIF.
  ENDMETHOD.


  METHOD po_del.
    DATA:ls_head  TYPE bapimepoheader,
         ls_headx TYPE bapimepoheaderx.
    ls_head = VALUE #( po_number = i_ebeln
                                    delete_ind = 'X' ).
    ls_headx = VALUE #( po_number = 'X'
                                    delete_ind = 'X' ).

    CALL FUNCTION 'BAPI_PO_CHANGE'
      EXPORTING
        purchaseorder = i_ebeln
        poheader      = ls_head
        poheaderx     = ls_headx
      TABLES
        return        = r_return.

  ENDMETHOD.


  METHOD pr_del.

    DATA:lt_bapieband TYPE TABLE OF bapieband.
    SELECT
      bnfpo AS preq_item,
      'X' AS  delete_ind,
      'X' AS  closed
      from eban
      WHERE banfn = @i_banfn
      INTO TABLE @lt_bapieband.
    CALL FUNCTION 'BAPI_REQUISITION_DELETE'
      EXPORTING
        number                      = i_banfn
      TABLES
        requisition_items_to_delete = lt_bapieband
        return                      = r_return.
  ENDMETHOD.


  METHOD so_del.
    DATA:order_header_inx type  bapisdh1x.
    order_header_inx-updateflag = 'D'.

    CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
      EXPORTING
        salesdocument    = i_vbeln_va
        order_header_inx = order_header_inx
      TABLES
        return           = r_return.
  ENDMETHOD.


  METHOD vl_del.
    DATA: ls_header_data    type bapiobdlvhdrchg,
          ls_header_control type bapiobdlvhdrctrlchg.
    ls_header_data-deliv_numb = i_vbeln_vl.
    ls_header_control = VALUE #( deliv_numb = i_vbeln_vl
                                                  dlv_del = 'X' ).
    CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
      EXPORTING
        header_data    = ls_header_data
        header_control = ls_header_control
        delivery       = i_vbeln_vl
      TABLES
        return         = r_return.

  ENDMETHOD.
ENDCLASS.
