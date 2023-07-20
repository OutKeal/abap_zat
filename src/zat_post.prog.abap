*&---------------------------------------------------------------------*
*& Report ZAT_POST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zat_post.

TABLES zatt_head.
DATA:return TYPE TABLE OF bapiret2 WITH HEADER LINE.

SELECT-OPTIONS:
              s_atno FOR zatt_head-atno,
              s_exord FOR zatt_head-exord,
              s_status FOR zatt_head-status OBLIGATORY,
              s_type FOR zatt_head-type ,
              s_erdat FOR zatt_head-erdat .

START-OF-SELECTION.

  SELECT * FROM zatt_head
    WHERE atno IN @s_atno
    AND exord IN @s_exord
    AND status IN @s_status
    AND type IN @s_type
    AND erdat IN @s_erdat
    AND status IN ('E' , 'A' )
    INTO TABLE @DATA(lt_head).
  IF sy-subrc NE 0.
    WRITE: '无数据' ,/.
    RETURN.
  ENDIF.

  LOOP AT lt_head INTO DATA(ls_head).
    CALL FUNCTION 'ZAT_POST'
      EXPORTING
        iv_type   = ls_head-type
        iv_atno   = ls_head-atno
        iv_budat  = ls_head-budat
      TABLES
        et_return = return[].
    LOOP AT return.
      WRITE: |{ return-type }-{ return-message }|.
    ENDLOOP.
  ENDLOOP.
