*&---------------------------------------------------------------------*
*& Report ZAT_QUERY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zat_query.

INCLUDE: zat_query_dat.

INCLUDE: zat_query_scr.

INCLUDE: zat_query_alv.

INCLUDE: zat_query_f01.


INITIALIZATION.


  IF s_erdat[] IS INITIAL.
    APPEND  VALUE #( sign = 'I'
                                     option = 'BT'
                                     low = sy-datum - 3
                                     high = sy-datum
                                  ) TO s_erdat.
  ENDIF.

START-OF-SELECTION.

  IF s_budat[] IS INITIAL AND s_erdat[] IS INITIAL.
    MESSAGE '请输入过账日期或者创建日期' TYPE 'S' DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

  PERFORM frm_get_data.

  IF gt_head[] IS INITIAL.
    MESSAGE '没有符合条件的数据' TYPE 'S' DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

  PERFORM frm_deal_data.
  gv_m = 'C'.

  CALL SCREEN 100.
