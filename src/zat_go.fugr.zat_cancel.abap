FUNCTION zat_cancel.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_EXORD) TYPE  ZATD_EXORD OPTIONAL
*"     VALUE(IV_ATNO) TYPE  ZATD_ATNO OPTIONAL
*"     VALUE(IV_TYPE) TYPE  ZATD_TYPE
*"     VALUE(IV_BUDAT) TYPE  BUDAT
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
  CALL FUNCTION 'ZAT_CLEAR'.
  g_type = iv_type.
  g_budat = iv_budat.

  SELECT SINGLE * FROM zatt_head
  WHERE ( atno = @iv_atno OR exord = @iv_exord )
  AND type = @iv_type
  INTO  @gs_head.
  IF sy-subrc EQ 0.
    iv_atno = gs_head-atno.
    iv_exord = gs_head-exord.
  ENDIF.

  SELECT * FROM zatt_item
  WHERE atno = @iv_atno
  INTO TABLE @gt_item.

  SELECT * FROM zatt_item_step
  WHERE atno = @iv_atno
  INTO TABLE @gt_item_step.


  IF gs_head IS INITIAL
  OR gt_item[] IS INITIAL
  OR gt_item_step[] IS INITIAL.
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' '获取数据失败' '' '' ''.
  ENDIF.


  CASE gs_head-status.
    WHEN 'A'.
      PERFORM frm_update_head_status USING gs_head 'D'.
      COMMIT WORK AND WAIT.
    WHEN 'D'.
      PERFORM frm_add_msg USING 'S'  'ZAT' '000' gs_head-atno '已经被作废' '' ''.
    WHEN 'E' OR 'C' OR 'F'.
      PERFORM frm_step_cancel .
  ENDCASE.

  et_return[] = gt_return[].

ENDFUNCTION.
